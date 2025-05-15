import UIKit
import FirebaseAuth
import FirebaseFirestore

class HomeViewController: BaseViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    // MARK: - Outlets
    @IBOutlet weak var streakCountLabel: UILabel!
    @IBOutlet weak var dailyTipLabel: UILabel!
    
    @IBOutlet weak var mondayView: UIView!
    @IBOutlet weak var tuesdayView: UIView!
    @IBOutlet weak var wednesdayView: UIView!
    @IBOutlet weak var thursdayView: UIView!
    @IBOutlet weak var fridayView: UIView!
    @IBOutlet weak var saturdayView: UIView!
    @IBOutlet weak var sundayView: UIView!
    
    @IBOutlet weak var SleepStreakView: UIView!
    @IBOutlet weak var DailyTipView: UIView!
    @IBOutlet weak var PreviouslyPlayedView: UIView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    // Sound items (using Music model)
    var soundItems: [MusicEntity] = DataModel1.getAllMusic()

    // MARK: - Properties
    var dayViews: [UIView] = []
    
    // Streak count property (updates label when set)
    var streakCount: Int = 0 {
        didSet {
            streakCountLabel.text = "\(streakCount) days"
        }
    }
    
    // Simulated sleep scores for 7 days
    var sleepScores: [Int] = HomeDataModel.defaultSleepScores

    // Daily Tips
    let dailyTips: [String] = HomeDataModel.dailyTips

    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchUserData()
        
        // Setup views and UI elements
        SleepStreakView.makeRounded()
        DailyTipView.makeRounded()
        PreviouslyPlayedView.makeRounded()
        
        // Apply 30x30 size and corner radius 10 to the day views
        [mondayView, tuesdayView, wednesdayView, thursdayView, fridayView, saturdayView, sundayView].forEach { view in
            view?.frame.size = CGSize(width: 30, height: 30)
            view?.layer.cornerRadius = 10
        }
        
        // Group day views into an array for easier management
        dayViews = [mondayView, tuesdayView, wednesdayView, thursdayView, fridayView, saturdayView, sundayView]
        
        // Load saved streak count
        streakCount = UserDefaults.standard.integer(forKey: "streakCount")
        
        // Update views and streak count based on sleep scores
        updateStreakAndViews()
        
        // Display daily tip
        displayDailyTip()
        
        // Set up the layout for the collection view
        let layout = UICollectionViewFlowLayout()
        let padding: CGFloat = 0 // space between cells
        let itemsPerRow: CGFloat = 2 // two columns
        
        let width = (collectionView.frame.width - padding * (itemsPerRow + 1)) / itemsPerRow
        layout.itemSize = CGSize(width: width, height: width)
        layout.minimumInteritemSpacing = padding
        layout.minimumLineSpacing = padding
        
        layout.scrollDirection = .horizontal
        
        let itemWidth = (view.frame.width - 100) / 3 // Three items per row now for a smaller image
        let itemHeight = itemWidth * 1
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 0
        
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        
        collectionView.setCollectionViewLayout(layout, animated: true)
        
        // Register the AudioCell class programmatically, not a NIB file
        collectionView.register(AudioCell.self, forCellWithReuseIdentifier: "AudioCell")
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Add streak listener
        StreakManager.shared.addStreakListener { [weak self] streak in
            self?.streakCount = streak
        }
        
        if let userId = Auth.auth().currentUser?.uid {
            StreakManager.shared.fetchCurrentStreak(userId: userId)
        }
    }
    
    //fetch User Data
    func fetchUserData() {
            let db = Firestore.firestore()
            if let user = Auth.auth().currentUser {
                let userRef = db.collection("users").document(user.uid)
                userRef.getDocument { (document, error) in
                    if let document = document, document.exists {
                        let userData = document.data()
                        print("User Data: \(userData?["name"] ?? "No name found")")
                    } else {
                        print("User document not found")
                    }
                }
            } else {
                print("No logged-in user")
            }
        }
    
    // MARK: - Streak Logic and View Updates
    func updateStreakAndViews() {
        var currentStreak = 0 // Tracks the ongoing streak
        var maxStreak = 0 // Tracks the maximum streak achieved in the current period

        // Iterate through sleep scores and update day views
        for (index, score) in sleepScores.enumerated() {
            let dayView = dayViews[index]
            dayView.layer.cornerRadius = 10

            if score >= 75 {
                dayView.backgroundColor = UIColor.systemTeal
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                dayView.backgroundColor = UIColor.systemGray
                currentStreak = 0 // Reset streak if score < 75
            }
        }

        streakCount = currentStreak // Update the streak count to the current streak
        UserDefaults.standard.set(streakCount, forKey: "streakCount") // Save streak count persistently
    }

    
    // MARK: - Add New Sleep Score (Daily Update)
    func addDailySleepScore(score: Int) {
        sleepScores.append(score)
        if sleepScores.count > 7 {
            sleepScores.removeFirst()
        }
        updateStreakAndViews()
    }
    
    func didSelectSound(_ sound: MusicEntity) {
        AudioManager.shared.play(track: sound) // Use 'play(track:)' instead of 'playTrack(_:)'
    }

    
    // MARK: - Daily Tip Logic
    func displayDailyTip() {
        let today = getCurrentDate()
        let savedDate = UserDefaults.standard.string(forKey: "dailyTipDate")
        let savedTip = UserDefaults.standard.string(forKey: "dailyTip")
        
        if savedDate == today, let tip = savedTip {
            dailyTipLabel.text = tip
        } else {
            let newTip = dailyTips.randomElement() ?? "Stay positive and keep improving your sleep!"
            UserDefaults.standard.set(today, forKey: "dailyTipDate")
            UserDefaults.standard.set(newTip, forKey: "dailyTip")
            dailyTipLabel.text = newTip
        }
    }
    
    // MARK: - Helper Function: Get Current Date
    func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    // MARK: - Collection View Data Source & Delegate
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return soundItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AudioCell.identifier, for: indexPath) as! AudioCell
        let sound = soundItems[indexPath.item]
        
        // Configure the cell with the music item
        cell.configure(with: sound)
        
        return cell
    }
}
