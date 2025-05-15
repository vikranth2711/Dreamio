import FirebaseFirestore
import CoreData
import FirebaseAuth
import Foundation
import Firebase

class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()
    
    // MARK: - Sync User from Firestore to Core Data
    func fetchUserFromFirestore(userID: String, completion: @escaping (UserEntity?) -> Void) {
        db.collection("users").document(userID).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user from Firestore: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let snapshot = snapshot, snapshot.exists, let data = snapshot.data() else {
                print("User document does not exist")
                completion(nil)
                return
            }

            let name = data["name"] as? String ?? ""
            let emailID = data["emailID"] as? String ?? ""
            let bedtime = (data["bedtime"] as? Timestamp)?.dateValue()
            let wakeupTime = (data["wakeupTime"] as? Timestamp)?.dateValue()
            let streak = data["streak"] as? Int ?? 0
            let userGenderString = data["userGender"] as? String ?? ""
            let userGender = Gender(rawValue: userGenderString)

            let user = CoreDataManager.shared.saveUser(userID: userID, name: name, emailID: emailID, bedtime: bedtime, wakeupTime: wakeupTime, streak: streak, userGender: userGender)

            completion(user)
        }
    }

    // MARK: - Sync User from Core Data to Firestore
    func syncUserToFirestore(user: UserEntity) {
        guard let userID = user.userID else {
            print("Error: UserID is nil, cannot sync to Firestore")
            return
        }

        let userRef = db.collection("users").document(userID)

        let data: [String: Any] = [
            "name": user.name,
            "emailID": user.emailID,
            "bedtime": user.bedtime ?? NSNull(),
            "wakeupTime": user.wakeupTime ?? NSNull(),
            "streak": user.streak,
            "userGender": user.userGender ?? NSNull()  // ✅ Sync gender
        ]

        userRef.setData(data, merge: true) { error in
            if let error = error {
                print("Error syncing user to Firestore: \(error.localizedDescription)")
            } else {
                print("User synced successfully to Firestore")
            }
        }
    }

}
