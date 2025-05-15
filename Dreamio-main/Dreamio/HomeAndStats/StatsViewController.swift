import UIKit
import FirebaseCore
import FirebaseAuth
import Charts
import FirebaseFirestore


class StatsViewController: BaseViewController {

    // UI Outlets
    @IBOutlet weak var streaksAndTimeView: UIView!
    @IBOutlet weak var dailyAlertView: UIView!
    @IBOutlet weak var lastNightSleepScoreView: UIView!
    @IBOutlet weak var sleepStagesGraphView: UIView!
    @IBOutlet weak var bedtimeView: UIView!
    @IBOutlet weak var wakeuptimeView: UIView!
    @IBOutlet weak var weeklySleepTimeView: UIView!
    @IBOutlet weak var sleepScoreView: UIView!
    @IBOutlet weak var streakLabel: UILabel!
    @IBOutlet weak var lastNightSleepDurationLabel: UILabel!
    @IBOutlet weak var dailyAlertLabel: UILabel!
    @IBOutlet weak var sleepImprovementReasonLabel: UILabel!
    @IBOutlet weak var bedtimeLabel: UILabel!
    @IBOutlet weak var wakeupTimeLabel: UILabel!

    
    // Data Model
    private var firestoreSleepData: [FirestoreSleepData] = []
    private var userProfile: FirestoreUserProfile?
    private var profileListener: ListenerRegistration?
    private var sleepDataListener: ListenerRegistration?
    
    // Scheduled Bedtime and Wake-up Time properties
    var scheduledBedtime: Date?
    var scheduledWakeUpTime: Date?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewAppearance()          // Applies a consistent rounded-corner style to views.
        setupFirestoreListeners()      // Sets up real-time listeners to fetch user profile and sleep data from Firestore.
        HealthkitSyncToFirebase()      // Initiates HealthKit authorization and data syncing.
        
        // Add streak listener
        StreakManager.shared.addStreakListener { [weak self] streak in
            DispatchQueue.main.async {
                self?.streakLabel.text = "🔥 \(streak)"
            }
        }
    }

    func setupSleepScoreRing() {
        guard let lastNight = getLastNightSleepData() else { return }
        let sleepScore = calculateSleepScore(from: lastNight)
    
        // Update the scoreLabel with dynamic data
        // Clear existing subviews and layers
        sleepScoreView.subviews.forEach { $0.removeFromSuperview() }
        sleepScoreView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        // Configure dimensions
        let ringWidth: CGFloat = 20 // Adjust this for a thicker ring
        let ringRadius = (min(sleepScoreView.bounds.width, sleepScoreView.bounds.height) / 2) - ringWidth - 10
        let ringCenter = CGPoint(x: sleepScoreView.bounds.midX, y: sleepScoreView.bounds.midY)

        // Background Ring
        let backgroundRing = CAShapeLayer()
        let circularPath = UIBezierPath(arcCenter: ringCenter, radius: ringRadius, startAngle: -CGFloat.pi / 2, endAngle: 1.5 * CGFloat.pi, clockwise: true)
        backgroundRing.path = circularPath.cgPath
        backgroundRing.strokeColor = UIColor.systemGray4.cgColor
        backgroundRing.lineWidth = ringWidth
        backgroundRing.fillColor = UIColor.clear.cgColor
        sleepScoreView.layer.addSublayer(backgroundRing)
        
        // Progress Ring
        let progressRing = CAShapeLayer()
        progressRing.path = circularPath.cgPath
        progressRing.strokeColor = UIColor.systemTeal.cgColor
        progressRing.lineWidth = ringWidth
        progressRing.fillColor = UIColor.clear.cgColor
        progressRing.lineCap = .round
        progressRing.strokeEnd = 0 // Initially 0
        sleepScoreView.layer.addSublayer(progressRing)

        // Center Text
        let scoreLabel = UILabel()
        scoreLabel.text = "\(sleepScore)%"
        scoreLabel.font = UIFont.boldSystemFont(ofSize: 32)
        scoreLabel.textColor = UIColor.label
        scoreLabel.textAlignment = .center
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        sleepScoreView.addSubview(scoreLabel)

        let descriptionLabel = UILabel()
        descriptionLabel.text = "Sleep Score"
        descriptionLabel.font = UIFont.systemFont(ofSize: 16)
        descriptionLabel.textColor = UIColor.secondaryLabel
        descriptionLabel.textAlignment = .center
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        sleepScoreView.addSubview(descriptionLabel)

        // Center the labels in the view
        NSLayoutConstraint.activate([
            scoreLabel.centerXAnchor.constraint(equalTo: sleepScoreView.centerXAnchor),
            scoreLabel.centerYAnchor.constraint(equalTo: sleepScoreView.centerYAnchor, constant: -10),
            descriptionLabel.centerXAnchor.constraint(equalTo: sleepScoreView.centerXAnchor),
            descriptionLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor, constant: 4)
        ])

        // Animate Progress
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.toValue = Double(sleepScore) / 100.0
        animation.duration = 1.0
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        progressRing.add(animation, forKey: "progressAnimation")
    }


    func setupSleepStagesGraph() {
        
        guard let lastNight = getLastNightSleepData() else { return }
        
        // Convert Firestore data to chart format
        let sleepStagesData = lastNight.segments.map { segment -> (time: String, stage: SleepStage) in
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return (
                time: formatter.string(from: segment.startTime),
                stage: mapFirestoreStage(segment.value)
            )
        }
        
        let lineChart = LineChartView(frame: sleepStagesGraphView.bounds)
        sleepStagesGraphView.addSubview(lineChart)

        let headingLabel = UILabel()
    //        headingLabel.text = "Last night"
        headingLabel.font = UIFont.boldSystemFont(ofSize: 16)
        headingLabel.textColor = .gray
        headingLabel.backgroundColor = .secondarySystemBackground
        headingLabel.translatesAutoresizingMaskIntoConstraints = false
        sleepStagesGraphView.addSubview(headingLabel)

        NSLayoutConstraint.activate([
            headingLabel.topAnchor.constraint(equalTo: sleepStagesGraphView.topAnchor, constant: 10),
            headingLabel.trailingAnchor.constraint(equalTo: sleepStagesGraphView.centerXAnchor)
        ])

        var chartEntries: [ChartDataEntry] = []
        let stageMapping: [SleepStage: Double] = [
            .awake: 3,
            .rem: 2,
            .lightSleep: 1,
            .deepSleep: 0
        ]

        for (index, data) in sleepStagesData.enumerated() {
            if let yValue = stageMapping[data.stage] {
                chartEntries.append(ChartDataEntry(x: Double(index), y: yValue))
            }
        }

        let dataSet = LineChartDataSet(entries: chartEntries, label: "")
        dataSet.colors = [UIColor.systemTeal]
        dataSet.lineWidth = 2.5
        dataSet.circleRadius = 0
        dataSet.drawValuesEnabled = false
        dataSet.mode = .cubicBezier
        dataSet.drawFilledEnabled = true

        // Gradient
        let gradientColors = [
            UIColor.systemBlue.withAlphaComponent(0.2).cgColor,
            UIColor.systemTeal.withAlphaComponent(1).cgColor
        ] as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors, locations: [0.0, 1.0])!
        dataSet.fill = LinearGradientFill(gradient: gradient, angle: 90.0)

        let data = LineChartData(dataSet: dataSet)
        lineChart.data = data

        // X-Axis Configuration
        lineChart.xAxis.valueFormatter = IndexAxisValueFormatter(values: sleepStagesData.map { $0.time })
        lineChart.xAxis.labelPosition = .bottom
        lineChart.xAxis.drawGridLinesEnabled = true
        lineChart.xAxis.gridColor = UIColor.gray.withAlphaComponent(0.5)
        lineChart.xAxis.axisLineColor = UIColor.gray
        lineChart.xAxis.axisLineWidth = 1.0

        // Y-Axis Configuration
        let leftAxis = lineChart.leftAxis
        leftAxis.enabled = true
        leftAxis.labelTextColor = .gray
        leftAxis.drawGridLinesEnabled = true
        leftAxis.gridColor = UIColor.gray.withAlphaComponent(0.5)
        leftAxis.axisLineColor = UIColor.gray // Show axis line
        leftAxis.labelPosition = .outsideChart // Make sure labels are outside the chart
        
        // Set custom Y-axis values for stages
        leftAxis.valueFormatter = IndexAxisValueFormatter(values: ["Deep", "Light", "REM", "Awake"])

        // Disable right Y-axis
        lineChart.rightAxis.enabled = false

        // General Chart Configuration
        lineChart.backgroundColor = .clear
        lineChart.drawGridBackgroundEnabled = false
        lineChart.drawBordersEnabled = false

        // Disable legend
        lineChart.legend.enabled = false
    }

    func setupWeeklySleepTimeGraph() {
        
        // Convert firestoreSleepData to weekly format
        let weeklyData = firestoreSleepData.sorted(by: { $0.date < $1.date }).map { data -> (day: String, sleepDuration: Double) in
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            return (
                day: formatter.string(from: data.date),
                sleepDuration: data.totalSleep / 60  // Convert minutes to hours
            )
        }
        
        let lineChart = LineChartView(frame: weeklySleepTimeView.bounds)
        weeklySleepTimeView.addSubview(lineChart)

        let headingLabel = UILabel()
        headingLabel.font = UIFont.boldSystemFont(ofSize: 16)
        headingLabel.textColor = .gray
        headingLabel.backgroundColor = .secondarySystemBackground
        headingLabel.translatesAutoresizingMaskIntoConstraints = false
        weeklySleepTimeView.addSubview(headingLabel)

        NSLayoutConstraint.activate([
            headingLabel.topAnchor.constraint(equalTo: weeklySleepTimeView.topAnchor, constant: 10),
            headingLabel.trailingAnchor.constraint(equalTo: weeklySleepTimeView.centerXAnchor)
        ])

        let chartEntries = weeklyData.enumerated().map { index, data in
            ChartDataEntry(x: Double(index), y: data.sleepDuration)
        }

        let dataSet = LineChartDataSet(entries: chartEntries, label: "")
        dataSet.colors = [UIColor.systemTeal]
        dataSet.circleColors = [UIColor.systemTeal]
        dataSet.circleHoleColor = UIColor.systemTeal
        dataSet.lineWidth = 2.5
        dataSet.circleRadius = 4
        dataSet.drawFilledEnabled = true

        // Updated Gradient with increased color intensity
        let gradientColors = [
            UIColor.systemTeal.withAlphaComponent(0.4).cgColor,  // Lighter color at the top (more intense)
            UIColor.systemTeal.withAlphaComponent(1.0).cgColor   // Darker color at the bottom (more intense)
        ] as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors, locations: [0.0, 1.0])!
        dataSet.fill = LinearGradientFill(gradient: gradient, angle: 90.0)

        let data = LineChartData(dataSet: dataSet)
        lineChart.data = data

        // X-Axis Configuration
        lineChart.xAxis.valueFormatter = IndexAxisValueFormatter(values: weeklyData.map { $0.day })
        lineChart.xAxis.labelPosition = .bottom
        lineChart.xAxis.drawGridLinesEnabled = false
        lineChart.xAxis.axisLineColor = UIColor.gray
        lineChart.xAxis.axisLineWidth = 1.0

        // Y-Axis Configuration
        let leftAxis = lineChart.leftAxis
        leftAxis.enabled = true
        leftAxis.labelTextColor = .gray
        leftAxis.drawGridLinesEnabled = true
        leftAxis.gridColor = UIColor.gray.withAlphaComponent(0.5)
        leftAxis.axisLineColor = UIColor.gray
        leftAxis.labelPosition = .outsideChart

        // You can set custom limits on the Y-axis if needed
        leftAxis.axisMinimum = 5 // Minimum sleep hours (adjust as needed)
        leftAxis.axisMaximum = 9 // Maximum sleep hours (adjust as needed)

        // Disable right Y-axis
        lineChart.rightAxis.enabled = false

        lineChart.leftAxis.valueFormatter = DefaultAxisValueFormatter { value, _ in
            "\(Int(value))hrs"
        }
        // General Chart Configuration
        lineChart.backgroundColor = .clear
        lineChart.drawGridBackgroundEnabled = false
        lineChart.drawBordersEnabled = false

        // Disable legend
        lineChart.legend.enabled = false
    }

    private func mapFirestoreStage(_ value: String) -> SleepStage {
        switch value {
        case "DEEP": return .deepSleep
        case "CORE": return .lightSleep
        case "REM": return .rem
        case "AWAKE": return .awake
        case "INBED": return .lightSleep
        default: return .awake
        }
    }

    private func displayLastNightSleepDuration() {
        guard let lastNight = getLastNightSleepData() else {
            lastNightSleepDurationLabel.text = "N/A"
            return
        }
        
        let actualSleep = calculateActualSleep(from: lastNight)
        let hours = Int(actualSleep) / 60
        let minutes = Int(actualSleep) % 60
        lastNightSleepDurationLabel.text = "\(hours)h\(minutes)m"
    }

    func updateDailyAlertMessage() {
        let alertMessage = "Your sleep schedule was adhered to. Great job!"
        dailyAlertLabel.text = alertMessage
    }

    func displaySleepImprovementReason() {
//        sleepImprovementReasonLabel.text = statsdataModel.sleepImprovementReason
    }
    
    func didSelectSound(_ sound: MusicEntity) {
        AudioManager.shared.play(track: sound) // Use 'play(track:)' instead of 'playTrack(_:)'
    }


    func updateScheduledTimes() {
        if let bedtime = scheduledBedtime {
            bedtimeLabel.text = formattedTime(bedtime)
        }
        if let wakeUpTime = scheduledWakeUpTime {
            wakeupTimeLabel.text = formattedTime(wakeUpTime)
        }
    }
    
    @IBAction func showSleepScoreInfo(_ sender: UIButton) {
        let alert = UIAlertController(
            title: "Sleep Score",
            message: "Calculated based on:\n- Sleep Duration (40%)\n- Schedule Consistency (30%)\n- Sleep Quality (30%)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @IBAction func showSleepStateGraphInfo(_ sender: UIButton) {
        let message = """
        
        REM Sleep: The stage where most dreaming occurs, essential for memory and emotional regulation.
        
        Light Sleep: A transition stage where your body prepares for deeper sleep.
        
        Deep Sleep: The most restorative stage, aiding physical recovery and muscle repair.
        
        Awake: The times when you briefly wake up during the night. Occasional awakenings are normal.
        """

        let alert = UIAlertController(title: "Sleep Stages", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        alert.view.tintColor = .systemTeal
    }



    @IBAction func editBedtimeTapped(_ sender: UIButton) {
        showTimePickerAlert(for: "Bedtime")
    }

    @IBAction func editWakeUpTimeTapped(_ sender: UIButton) {
        showTimePickerAlert(for: "Wake-up Time")
    }

    // Function to show the alert with a time picker
    func showTimePickerAlert(for timeType: String) {
        let alert = UIAlertController(title: "\(timeType) Picker", message: nil, preferredStyle: .alert)
        alert.view.tintColor = .systemTeal
        let timePicker = UIDatePicker()
        timePicker.datePickerMode = .time
        alert.view.addSubview(timePicker)
        
        timePicker.translatesAutoresizingMaskIntoConstraints = false
        timePicker.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor).isActive = true
        timePicker.centerYAnchor.constraint(equalTo: alert.view.centerYAnchor).isActive = true
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            let selectedTime = timePicker.date
            if timeType == "Bedtime" {
                self.scheduledBedtime = selectedTime
            } else {
                self.scheduledWakeUpTime = selectedTime
            }
            self.updateScheduledTimes()
        }
        alert.addAction(saveAction)
        
        present(alert, animated: true)
    }

    func formattedTime(_ time: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter.string(from: time)
    }
}

extension StatsViewController {
    private func setupFirestoreListeners() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        // Profile Listener
        let profileRef = db.collection("users").document(userId)
        profileListener = profileRef.addSnapshotListener { [weak self] document, _ in
            guard let data = document?.data() else { return }
            self?.userProfile = FirestoreUserProfile(
                streak: data["streak"] as? Int ?? 0,
                bedtime: data["bedtime"] as? String ?? "--:--",
                wakeupTime: data["wakeupTime"] as? String ?? "--:--"
            )
            self?.updateUIWithProfile()
        }
        
        // Sleep Data Listener (last 7 days)
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let sleepRef = db.collection("users").document(userId)
            .collection("sleepData")
            .whereField("startOfDay", isGreaterThanOrEqualTo: Timestamp(date: sevenDaysAgo))
        
        sleepDataListener = sleepRef.addSnapshotListener { [weak self] querySnapshot, _ in
            guard let self = self, let documents = querySnapshot?.documents else { return }
            
            var sleepDataArray: [FirestoreSleepData] = []
            let dispatchGroup = DispatchGroup()
            
            // Loop over each sleepData document.
            for doc in documents {
                guard let startOfDay = doc.get("startOfDay") as? Timestamp,
                      let totalSleep = doc.get("totalSleepDuration") as? Double else { continue }
                
                // Enter the group before starting the async fetch for sleep segments.
                dispatchGroup.enter()
                doc.reference.collection("sleepSegments").getDocuments { segmentSnapshot, _ in
                    let segments = segmentSnapshot?.documents.compactMap { segmentDoc -> FirestoreSleepData.SleepSegment? in
                        guard let start = segmentDoc.get("startTime") as? Timestamp,
                              let end = segmentDoc.get("endTime") as? Timestamp,
                              let value = segmentDoc.get("value") as? String,
                              let duration = segmentDoc.get("duration") as? Double else {
                            return nil
                        }
                        return FirestoreSleepData.SleepSegment(
                            startTime: start.dateValue(),
                            endTime: end.dateValue(),
                            value: value,
                            duration: duration
                        )
                    } ?? []
                    
                    sleepDataArray.append(FirestoreSleepData(
                        date: startOfDay.dateValue(),
                        totalSleep: totalSleep,
                        segments: segments
                    ))
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                self.firestoreSleepData = sleepDataArray.sorted(by: { $0.date < $1.date })
                self.updateCharts()
            }
        }
    }
}

extension StatsViewController {
    // MARK: - UI Updates
    private func updateUIWithProfile() {
        guard let profile = userProfile else { return }
        streakLabel.text = "🔥 \(profile.streak)"
        bedtimeLabel.text = profile.bedtime
        wakeupTimeLabel.text = profile.wakeupTime
    }
    
    private func updateCharts() {
        setupSleepScoreRing()
        setupSleepStagesGraph()
        setupWeeklySleepTimeGraph()
        displayLastNightSleepDuration()
        updateDailyAlertMessage()
    }
    
    // MARK: - Data Processing
    private func getLastNightSleepData() -> FirestoreSleepData? {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        return firestoreSleepData.first { calendar.isDate($0.date, inSameDayAs: yesterday) }
    }
    
    private func calculateActualSleep(from data: FirestoreSleepData) -> Double {
        return data.segments.filter { ["REM", "CORE", "DEEP"].contains($0.value) }
            .reduce(0) { $0 + $1.duration }
    }
}

extension StatsViewController {
    private func calculateSleepScore(from data: FirestoreSleepData) -> Int {
        let actualSleep = calculateActualSleep(from: data)
        
        // 1. Duration Score (40%)
        let targetDuration = 8 * 60.0 // 8 hours in minutes
        let durationDifference = abs(actualSleep - targetDuration)
        let durationScore = max(0, 40 - Int((durationDifference / 60) * 5))
        
        // 2. Consistency Score (30%)
        var consistencyScore = 0
        if let scheduledBedtime = scheduledBedtime,
           let scheduledWakeUp = scheduledWakeUpTime {
            
            let bedtimeComponents = Calendar.current.dateComponents([.hour, .minute], from: scheduledBedtime)
            let actualBedtime = data.segments.first?.startTime ?? Date()
            let actualBedtimeComponents = Calendar.current.dateComponents([.hour, .minute], from: actualBedtime)
            
            let bedtimeDiff = abs((bedtimeComponents.hour ?? 0) - (actualBedtimeComponents.hour ?? 0)) * 60
                + abs((bedtimeComponents.minute ?? 0) - (actualBedtimeComponents.minute ?? 0))
            
            consistencyScore = max(0, 30 - (bedtimeDiff / 10))
        }
        
        // 3. Sleep Quality Score (30%)
        let totalStageTime = data.segments.filter { ["REM", "CORE", "DEEP"].contains($0.value) }
            .reduce(0) { $0 + $1.duration }
        
        let deepRemDuration = data.segments.filter { ["DEEP", "REM"].contains($0.value) }
            .reduce(0) { $0 + $1.duration }
        
        let qualityPercentage = totalStageTime > 0 ? (deepRemDuration / totalStageTime) : 0
        let qualityScore = Int(qualityPercentage * 30)
        
        return min(100, durationScore + consistencyScore + qualityScore)
    }
    
    // MARK: - UI Setup
    private func setupViewAppearance() {
        [streaksAndTimeView, dailyAlertView, lastNightSleepScoreView,
         sleepStagesGraphView, bedtimeView, wakeuptimeView, weeklySleepTimeView].forEach {
            $0?.makeRounded()
            $0?.backgroundColor = .secondarySystemBackground
        }
    }
    
    private func HealthkitSyncToFirebase(){
        // Request HealthKit authorization first.
        HealthKitManager.shared.requestAuthorization { success, error in
            if success {
                print("HealthKit authorized!")
                
                // Define the date range for the query.
                let calendar = Calendar.current
                let now = Date()
                guard let startDate = calendar.date(byAdding: .day, value: -7, to: now) else { return }
                
                // Fetch sleep data from HealthKit for the last 7 days.
                HealthKitManager.shared.fetchSleepData(startDate: startDate, endDate: now) { samples in
                    guard let samples = samples else {
                        print("No sleep data fetched.")
                        return
                    }
                    
                    // Process the fetched samples.
                    HealthKitManager.shared.processSleepData(samples: samples)
                    
                    // Optionally, if you have processed SleepStageData ready to sync:
                    // let processedSleepData: [SleepStageData] = ... // Your processed data
                    // HealthKitManager.shared.syncSleepDataToFirebase(processedSleepData)
                }
            } else {
                print("Authorization failed: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}

extension UIView {
    func makeRounded() {
        self.layer.cornerRadius = 12
        self.layer.masksToBounds = true
    }
}

