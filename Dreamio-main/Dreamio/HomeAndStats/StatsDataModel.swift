
import Foundation

// Enum to represent different sleep stages
enum SleepStage: String {
    case awake = "Awake"
    case rem = "REM"
    case lightSleep = "Light Sleep"
    case deepSleep = "Deep Sleep"
}

// Model to store individual sleep stage data
struct SleepStageData {
    let time: String
    let stage: SleepStage
}

// Model to store weekly sleep data
struct WeeklySleepData {
    let day: String
    let sleepDuration: Double // in hours
}

// Model to store the sleep score
struct SleepScoreData {
    let score: Int // sleep score percentage
    let date: Date // date of the sleep score record
}

// Enum for sleep improvement methods
enum ImprovementMethod {
    case sleepSounds
    case breathingExercise
    case redLight
}
