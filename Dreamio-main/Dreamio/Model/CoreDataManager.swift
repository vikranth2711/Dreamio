import CoreData
import UIKit

class CoreDataManager {
    static let shared = CoreDataManager()

    let context: NSManagedObjectContext

    private init() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.context = appDelegate.persistentContainer.viewContext
    }
    
    func delete(_ object: NSManagedObject) {
            context.delete(object)
            saveContext()
        }

    // Save context
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving Core Data context: \(error)")
            }
        }
    }

    // MARK: - Fetch Music Data
    func fetchMusicData() -> [MusicEntity] {
        let fetchRequest: NSFetchRequest<MusicEntity> = MusicEntity.fetchRequest()
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching music data: \(error)")
            return []
        }
    }

    // MARK: - Fetch Playlist Data
    func fetchPlaylistsData() -> [PlaylistEntity] {
        let fetchRequest: NSFetchRequest<PlaylistEntity> = PlaylistEntity.fetchRequest()
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching playlists data: \(error)")
            return []
        }
    }
    
    // MARK: - UserEntity CRUD Operations
    // Save or Update User
    func saveUser(userID: String, name: String, emailID: String, bedtime: Date?, wakeupTime: Date?, streak: Int, userGender: Gender?) -> UserEntity? {
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        request.predicate = NSPredicate(format: "userID == %@", userID)

        do {
            let users = try context.fetch(request)
            let user: UserEntity

            if let existingUser = users.first {
                user = existingUser
            } else {
                user = UserEntity(context: context) 
                user.userID = userID
            }

            user.name = name
            user.emailID = emailID
            user.bedtime = bedtime
            user.wakeupTime = wakeupTime
            user.streak = Int16(streak)
            user.userGender = userGender?.rawValue
            saveContext()
            return user
        } catch {
            print("Error saving user: \(error.localizedDescription)")
            return nil
        }
    }

    // Delete User
    func deleteUser(userID: String) {
        if let user = fetchUser(by: userID) {
            context.delete(user)
            saveContext()
        }
    }

    // Fetch User from Core Data
    func fetchUser(by userID: String) -> UserEntity? {
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        request.predicate = NSPredicate(format: "userID == %@", userID)
        
        do {
            return try context.fetch(request).first
        } catch {
            print("Error fetching user: \(error.localizedDescription)")
            return nil
        }
    }
}
