
import Foundation

struct UserProfile {
    var userID: String  // Add this field
    var sleepTime: Date
    var wakeUpTime: Date
    var gender: Gender
}

struct UserSleepData {
    static var profiles: [UserProfile] = []
}

enum Gender: String {
    case male = "Male"
    case female = "Female"
}

