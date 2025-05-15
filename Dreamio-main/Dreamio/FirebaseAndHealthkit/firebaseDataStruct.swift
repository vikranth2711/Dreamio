import Foundation

struct FirestoreSleepData {
    let date: Date
    let totalSleep: Double // Total minutes of actual sleep (CORE + DEEP + REM)
    let segments: [SleepSegment]
    
    struct SleepSegment {
        let startTime: Date
        let endTime: Date
        let value: String
        let duration: Double
    }
}

struct FirestoreUserProfile {
    let streak: Int
    let bedtime: String
    let wakeupTime: String
}


