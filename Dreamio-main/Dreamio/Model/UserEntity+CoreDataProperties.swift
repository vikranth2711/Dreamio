
import Foundation
import CoreData


extension UserEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserEntity> {
        return NSFetchRequest<UserEntity>(entityName: "UserEntity")
    }

    @NSManaged public var userID: String?
    @NSManaged public var name: String?
    @NSManaged public var emailID: String?
    @NSManaged public var bedtime: Date?
    @NSManaged public var wakeupTime: Date?
    @NSManaged public var streak: Int16
    @NSManaged public var userGender: String?

}
