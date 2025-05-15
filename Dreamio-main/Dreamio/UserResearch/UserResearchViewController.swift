import UIKit
import FirebaseAuth

class UserResearchViewController: UIViewController {

    @IBOutlet weak var selectGenderButton: UIButton!
    @IBOutlet weak var sleepTimePicker: UIDatePicker!
    @IBOutlet weak var wakeUpTimePicker: UIDatePicker!

    var userProfile = UserProfile(userID: "", sleepTime: Date(), wakeUpTime: Date(), gender: Gender.male)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureDatePickers()
        setupGenderSelectionMenu()
        loadUserData()
    }

    private func configureDatePickers() {
        sleepTimePicker.tintColor = .white
        wakeUpTimePicker.tintColor = .white
        sleepTimePicker.overrideUserInterfaceStyle = .dark
        wakeUpTimePicker.overrideUserInterfaceStyle = .dark
        sleepTimePicker.datePickerMode = .time
        wakeUpTimePicker.datePickerMode = .time
    }

    private func setupGenderSelectionMenu() {
        selectGenderButton.menu = UIMenu(title: "", children: [
            UIAction(title: "Male", handler: { _ in
                self.selectGenderButton.setTitle("Male", for: .normal)
                self.userProfile.gender = Gender.male
            }),
            UIAction(title: "Female", handler: { _ in
                self.selectGenderButton.setTitle("Female", for: .normal)
                self.userProfile.gender = Gender.female
            })
        ])
        selectGenderButton.showsMenuAsPrimaryAction = true
    }

    @IBAction func sleepTimeChanged(_ sender: UIDatePicker) {
        userProfile.sleepTime = adjustTimeForToday(date: sender.date)
    }

    @IBAction func wakeUpTimeChanged(_ sender: UIDatePicker) {
        userProfile.wakeUpTime = adjustTimeForToday(date: sender.date)
    }

    @IBAction func continueButtonTapped(_ sender: UIButton) {
            guard let user = Auth.auth().currentUser else {
                print("No authenticated user found")
                return
            }
            
            let userID = user.uid
            let name = "User Name"
            let sleepTime = userProfile.sleepTime
            let wakeUpTime = userProfile.wakeUpTime
            let genderString = userProfile.gender.rawValue

            if let savedUser = CoreDataManager.shared.saveUser(
                userID: userID,
                name: name,
                emailID: user.email ?? "",
                bedtime: sleepTime,
                wakeupTime: wakeUpTime,
                streak: 0,
                userGender: userProfile.gender
            ) {
                // Sync to Firestore and navigate
                FirestoreService.shared.syncUserToFirestore(user: savedUser)
                print("User profile saved & synced")
                
                // Add navigation here
                self.navigateToTabBarController()
            } else {
                print("Failed to save user")
            }
        }

        // Add navigation helper
        private func navigateToTabBarController() {
            if let tabBarController = storyboard?.instantiateViewController(
                withIdentifier: "MainTabBarController"
            ) as? UITabBarController {
                tabBarController.modalPresentationStyle = .fullScreen
                present(tabBarController, animated: true)
            }
        }

    private func loadUserData() {
        guard let user = Auth.auth().currentUser else {
            print("No authenticated user found")
            return
        }

        let userID = user.uid

        if let localUser = CoreDataManager.shared.fetchUser(by: userID) {
            // Load from Core Data
            userProfile.userID = localUser.userID ?? ""
            userProfile.sleepTime = localUser.bedtime ?? Date()
            userProfile.wakeUpTime = localUser.wakeupTime ?? Date()

            // ✅ Convert gender String to Enum
            if let genderString = localUser.userGender, let gender = Gender(rawValue: genderString) {
                userProfile.gender = gender
                selectGenderButton.setTitle(genderString, for: .normal)
            }
        } else {
            // Fetch from Firestore and save to Core Data
            FirestoreService.shared.fetchUserFromFirestore(userID: userID) { fetchedUser in
                if let fetchedUser = fetchedUser {
                    self.userProfile.userID = fetchedUser.userID ?? ""
                    self.userProfile.sleepTime = fetchedUser.bedtime ?? Date()
                    self.userProfile.wakeUpTime = fetchedUser.wakeupTime ?? Date()

                    // ✅ Convert gender String to Enum
                    if let genderString = fetchedUser.userGender, let gender = Gender(rawValue: genderString) {
                        self.userProfile.gender = gender
                        self.selectGenderButton.setTitle(genderString, for: .normal)
                    }

                    print("User data loaded from Firestore and saved to Core Data")
                }
            }
        }
    }

    private func adjustTimeForToday(date: Date) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        
        let components = calendar.dateComponents([.hour, .minute], from: date)
        
        var todayComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        todayComponents.hour = components.hour
        todayComponents.minute = components.minute
        todayComponents.second = 0
        return calendar.date(from: todayComponents) ?? date
    }
}
