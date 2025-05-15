import UIKit
import HealthKit

class ViewController: UIViewController {
    
    let healthStore = HKHealthStore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device.")
            return
        }
        requestAuthorization()
    }
    
    // Request authorization for sleep analysis data.
    func requestAuthorization() {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            fatalError("Sleep Analysis type is unavailable.")
        }
        
        let typesToShare: Set<HKSampleType> = [sleepType]
        let typesToRead: Set<HKObjectType> = [sleepType]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { [weak self] success, error in
            if success {
                print("Authorization successful")
                self?.writePastTenDaysSleepData()
            } else {
                print("Authorization failed: \(error?.localizedDescription ?? "unknown error")")
            }
        }
    }
    
    // Write dummy sleep data with randomized total sleep duration (3-10 hours)
    // and randomized sleep stage intervals for the past 10 days.
    func writePastTenDaysSleepData() {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        let calendar = Calendar.current
        let now = Date()
        
        for i in 1...10 {
            // Random total sleep duration between 3 hours (180 minutes) and 10 hours (600 minutes)
            let totalSleepMinutes = Int.random(in: 180...600)
            
            // Calculate the day for sleep data.
            guard let dayDate = calendar.date(byAdding: .day, value: -i, to: now) else { continue }
            // Set wake time to 7:00 AM on that day.
            guard let wakeTime = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: dayDate) else { continue }
            // Calculate bed time by subtracting the total sleep duration from wake time.
            guard let bedTime = calendar.date(byAdding: .minute, value: -totalSleepMinutes, to: wakeTime) else { continue }
            
            var initialDelay = 0, coreMinutes = 0, deepMinutes = 0, remMinutes = 0, awakeMinutes = 0
            
            // Generate random durations for the sleep stages.
            // The ranges adjust based on totalSleepMinutes.
            // initialDelay: 0 to min(45 minutes, 1/5th of total sleep)
            // core, deep, rem: each at least 20 minutes up to a maximum of min(120, half of total sleep)
            // awakeMinutes: computed as the remainder; must be at least 15 minutes.
            repeat {
                initialDelay = Int.random(in: 0...min(45, totalSleepMinutes/5))
                coreMinutes  = Int.random(in: 20...min(120, totalSleepMinutes/2))
                deepMinutes  = Int.random(in: 20...min(120, totalSleepMinutes/2))
                remMinutes   = Int.random(in: 20...min(120, totalSleepMinutes/2))
                awakeMinutes = totalSleepMinutes - (initialDelay + coreMinutes + deepMinutes + remMinutes)
            } while awakeMinutes < 15
            
            // Calculate the start and end times for each sleep stage.
            let coreStart  = calendar.date(byAdding: .minute, value: initialDelay, to: bedTime)!
            let coreEnd    = calendar.date(byAdding: .minute, value: coreMinutes, to: coreStart)!
            let deepStart  = coreEnd
            let deepEnd    = calendar.date(byAdding: .minute, value: deepMinutes, to: deepStart)!
            let remStart   = deepEnd
            let remEnd     = calendar.date(byAdding: .minute, value: remMinutes, to: remStart)!
            let awakeStart = remEnd  // Awake period from here until wakeTime
            
            // Create the overall inBed sample covering the entire sleep period.
            let inBedSample = HKCategorySample(
                type: sleepType,
                value: HKCategoryValueSleepAnalysis.inBed.rawValue,
                start: bedTime,
                end: wakeTime
            )
            
            // Create detailed sleep stage samples.
            let coreSample = HKCategorySample(
                type: sleepType,
                value: HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                start: coreStart,
                end: coreEnd
            )
            let deepSample = HKCategorySample(
                type: sleepType,
                value: HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                start: deepStart,
                end: deepEnd
            )
            let remSample = HKCategorySample(
                type: sleepType,
                value: HKCategoryValueSleepAnalysis.asleepREM.rawValue,
                start: remStart,
                end: remEnd
            )
            let awakeSample = HKCategorySample(
                type: sleepType,
                value: HKCategoryValueSleepAnalysis.awake.rawValue,
                start: awakeStart,
                end: wakeTime
            )
            
            // Save all samples to HealthKit.
            let samples = [inBedSample, coreSample, deepSample, remSample, awakeSample]
            for sample in samples {
                healthStore.save(sample) { success, error in
                    if success {
                        print("Successfully saved sample for day \(i): \(sample)")
                    } else {
                        print("Error saving sample for day \(i): \(error?.localizedDescription ?? "unknown error")")
                    }
                }
            }
        }
    }
}
