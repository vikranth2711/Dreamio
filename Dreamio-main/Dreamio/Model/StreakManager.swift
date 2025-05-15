import Foundation
import FirebaseFirestore

class StreakManager {
    static let shared = StreakManager()
    private var streakListeners: [(Int) -> Void] = []
    
    private init() {}
    
    func updateStreak(userId: String, totalSleep: Double) {
        let db = Firestore.firestore()
        // 360 minutes = 6 hours minimum for streak
        if totalSleep >= 360 {
            db.collection("users").document(userId).updateData([
                "streak": FieldValue.increment(Int64(1))
            ]) { [weak self] _ in
                self?.fetchCurrentStreak(userId: userId)
            }
        } else {
            db.collection("users").document(userId).updateData(["streak": 0]) { [weak self] _ in
                self?.notifyListeners(streak: 0)
            }
        }
    }
    
    func fetchCurrentStreak(userId: String) {
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { [weak self] document, _ in
            if let streak = document?.data()?["streak"] as? Int {
                self?.notifyListeners(streak: streak)
            }
        }
    }
    
    func addStreakListener(listener: @escaping (Int) -> Void) {
        streakListeners.append(listener)
    }
    
    private func notifyListeners(streak: Int) {
        streakListeners.forEach { $0(streak) }
    }
}