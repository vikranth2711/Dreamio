import HealthKit
import FirebaseAuth
import FirebaseFirestore

class HealthKitManager {
    static let shared = HealthKitManager()
    let healthStore = HKHealthStore()
    
    // Request HealthKit authorization
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion(false, nil)
            return
        }
        
        healthStore.requestAuthorization(toShare: nil, read: [sleepType], completion: completion)
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    func fetchSleepData(startDate: Date, endDate: Date, completion: @escaping ([HKSample]?) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion(nil)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(
            sampleType: sleepType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sort]
        ) { _, samples, _ in
            completion(samples)
        }
        
        healthStore.execute(query)
    }
    
    func syncSleepDataToFirebase(_ sleepData: [SleepStageData]) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateKey = dateFormatter.string(from: Date())
        
        let sleepCollection = db.collection("users").document(userID)
            .collection("stats").document(dateKey).collection("sleepStatsInfo")
        
        for data in sleepData {
            let docRef = sleepCollection.document()
            docRef.setData([
                "startTime": data.time,
                "sleepStage": data.stage.rawValue
            ])
        }
    }
    
    func processSleepData(samples: [HKSample]) {
        var sleepDataByDate = [String: [HKCategorySample]]()
        let calendar = Calendar.current
        
        for case let sample as HKCategorySample in samples {
            var currentStart = sample.startDate
            let endDate = sample.endDate
            
            while currentStart < endDate {
                let dayEnd = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: currentStart)!
                let segmentEnd = min(dayEnd, endDate)
                
                let dateKey = DateFormatter.yyyyMMdd.string(from: currentStart)
                let segment = HKCategorySample(
                    type: sample.categoryType,
                    value: sample.value,
                    start: currentStart,
                    end: segmentEnd
                )
                
                sleepDataByDate[dateKey, default: []].append(segment)
                currentStart = calendar.date(byAdding: .day, value: 1, to: currentStart)!
            }
        }
        
        Task { await uploadToFirestore(sleepDataByDate: sleepDataByDate) }
    }
    
    /// Updated upload function that prevents duplicate writes by checking for existing segments.
    private func uploadToFirestore(sleepDataByDate: [String: [HKCategorySample]]) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let batch = db.batch()
        
        for (dateKey, samples) in sleepDataByDate {
            let dateRef = db.collection("users").document(userId)
                .collection("sleepData").document(dateKey)
            
            var totalSleep: Double = 0
            var segmentsAdded = 0
            
            for sample in samples {
                // Only count actual sleep stages (exclude INBED and AWAKE)
                guard [2, 3, 4].contains(sample.value) else { continue }
                
                let duration = sample.endDate.timeIntervalSince(sample.startDate) / 60 // Convert to minutes
                totalSleep += duration
                
                let segmentID = "\(Int(sample.startDate.timeIntervalSince1970))_\(Int(sample.endDate.timeIntervalSince1970))"
                let segmentRef = dateRef.collection("sleepSegments").document(segmentID)
                
                batch.setData([
                    "startTime": Timestamp(date: sample.startDate),
                    "endTime": Timestamp(date: sample.endDate),
                    "value": sleepStageString(value: sample.value),
                    "stageType": sample.value,
                    "duration": duration
                ], forDocument: segmentRef)
                
                segmentsAdded += 1
            }
            
            if segmentsAdded > 0 {
                batch.setData([
                    "startOfDay": Timestamp(date: DateFormatter.yyyyMMdd.date(from: dateKey)!),
                    "totalSleepDuration": totalSleep
                ], forDocument: dateRef, merge: true)
            }
        }
        
        do {
            try await batch.commit()
            print("Firestore update successful")
            updateStreakIfNeeded()
        } catch {
            print("Firestore update failed: \(error.localizedDescription)")
        }
    }
    
    private func updateStreakIfNeeded() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayKey = DateFormatter.yyyyMMdd.string(from: yesterday)
        
        db.collection("users").document(userId)
            .collection("sleepData").document(yesterdayKey).getDocument { snapshot, _ in
                guard let data = snapshot?.data(),
                      let totalSleep = data["totalSleepDuration"] as? Double else {
                    db.collection("users").document(userId).updateData(["streak": 0])
                    return
                }
                
                if totalSleep >= 360 { // 6 hours minimum
                    db.collection("users").document(userId).updateData([
                        "streak": FieldValue.increment(Int64(1))
                    ])
                } else {
                    db.collection("users").document(userId).updateData(["streak": 0])
                }
            }
    }
    
    /// Helper function to fetch existing sleep segment IDs for a given date document.
    private func getExistingSegments(dateRef: DocumentReference) async -> Set<String> {
        do {
            let querySnapshot = try await dateRef.collection("sleepSegments").getDocuments()
            return Set(querySnapshot.documents.map { $0.documentID })
        } catch {
            print("Error fetching existing segments: \(error)")
            return []
        }
    }
    
    private func sleepStageString(value: Int) -> String {
        switch value {
        case 0: return "INBED"
        case 1: return "AWAKE"
        case 2: return "CORE"
        case 3: return "DEEP"
        case 4: return "REM"
        default: return "UNKNOWN"
        }
    }
}

extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
