import UIKit
import AVFoundation
import CoreData
import FirebaseAuth
import FirebaseAnalytics
import FirebaseFirestore
import CoreMotion

class RedLightViewController: BaseViewController {
    
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var breathingView: UIView!
    @IBOutlet weak var animationSwitch: UISwitch!
    
    @IBOutlet weak var playlistCollectionView: UICollectionView!
    
    // Playlist properties
    var playlists: [PlaylistEntity] = []
    var audioPlayers: [AVAudioPlayer] = []
    var currentPlaylistIndex = 0
    
    // Timer
    var timer: Timer?
    var remainingTime = 1200 // 20 minutes in seconds
    var isRunning = false

    // CoreMotion
    let motionManager = CMMotionManager()
    let motionThreshold: Double = 0.2 // Adjust sensitivity
    var isMonitoring = false
    
    // Sleep tracking
    var bedtime: Date? // When the user presses "Start Sleeping"
    var sleepTime: Date? // 20 minutes after bedtime
    var wakeUpTime: Date? // When motion is detected or the user presses "Stop Sleeping"
    
    // Firestore
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialState()
        setupCollectionView()
        loadPlaylists()
        setupPlaylistCollectionViewConstraints()
    }
    
    func setupInitialState() {
        timerLabel.text = formatTime(remainingTime)
        startButton.setTitle("Start Sleeping", for: .normal)
        breathingView.backgroundColor = UIColor(red: 194/255, green: 8/255, blue: 8/255, alpha: 1)
        UIApplication.shared.isIdleTimerDisabled = false
        animationSwitch.isOn = true // Default to ON
    }
    
    func setupCollectionView() {
        playlistCollectionView.delegate = self
        playlistCollectionView.dataSource = self
        
        // Register cell
        playlistCollectionView.register(PlaylistCollectionViewCell.self, forCellWithReuseIdentifier: "PlaylistCell")
        
        // Configure layout
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 0
        
        // Calculate cell size
        let cellWidth = view.frame.width * 0.8
        let cellHeight: CGFloat = 80
        layout.itemSize = CGSize(width: cellWidth, height: cellHeight)
        
        // Set content insets
        playlistCollectionView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        playlistCollectionView.showsHorizontalScrollIndicator = false
        
        playlistCollectionView.backgroundColor = .clear
        playlistCollectionView.collectionViewLayout = layout
    }
    
    private func setupPlaylistCollectionViewConstraints() {
        playlistCollectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            playlistCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playlistCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playlistCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            playlistCollectionView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    func loadPlaylists() {
        playlists = DataModel1.getAllPlaylists()
        playlistCollectionView.reloadData()
    }
    
    // MARK: - Playlist Playback
    func playPlaylist(_ playlist: PlaylistEntity) {
        stopAllPlayback()
        
        // CORRECT: Use tracks instead of sounds
        guard let tracks = playlist.tracks?.allObjects as? [PlaylistTrack] else { return }
        
        audioPlayers = tracks.compactMap { track in
            guard let music = track.music,
                  let fileName = music.fileName,
                  let url = Bundle.main.url(forResource: fileName, withExtension: nil)
            else { return nil }
            
            let audioPlayer = try? AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = track.volume // Use volume from PlaylistTrack
            return audioPlayer
        }
        
        audioPlayers.forEach { $0.play() }
        updatePlayButtonState()
    }
    
    func stopAllPlayback() {
        audioPlayers.forEach { $0.stop() }
        audioPlayers.removeAll()
        updatePlayButtonState()
    }
    
    func updatePlayButtonState() {
        guard let cell = playlistCollectionView.cellForItem(at: IndexPath(item: currentPlaylistIndex, section: 0)) as? PlaylistCollectionViewCell else { return }
        
        let isPlaying = !audioPlayers.isEmpty
        cell.updatePlayButtonState(isPlaying: isPlaying)
    }
    
    @IBAction func startButtonTapped(_ sender: UIButton) {
        if isRunning {
            stopSleeping()
        } else {
            startSleeping()
        }
    }
    
    @IBAction func animationSwitchChanged(_ sender: UISwitch) {
        if sender.isOn {
            startColorTransition()
        } else {
            stopColorTransition()
        }
    }
    
    func startSleeping() {
        isRunning = true
        startButton.setTitle("Stop Sleeping", for: .normal)
        UIApplication.shared.isIdleTimerDisabled = true // Prevent auto-lock while the timer is running
        
        // Record bedtime
        bedtime = Date()
        logBedtime()
        
        // Calculate sleep time (20 minutes after bedtime)
        sleepTime = Calendar.current.date(byAdding: .minute, value: 20, to: bedtime!)
        
        // Start 20-minute timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.remainingTime -= 1
            self.timerLabel.text = self.formatTime(self.remainingTime)
            
            if self.remainingTime <= 0 {
                self.stopSleeping()
            }
        }
        
        // Start motion monitoring
        startMotionUpdates()
        isMonitoring = true
        
        // Start breathing animation
        startColorTransition()
    }
    
    func stopSleeping() {
        isRunning = false
        startButton.setTitle("Start Sleeping", for: .normal)
        UIApplication.shared.isIdleTimerDisabled = false // Allow auto-lock
        
        // Stop timer
        timer?.invalidate()
        timer = nil
        remainingTime = 1200 // Reset to 20 minutes
        timerLabel.text = formatTime(remainingTime)
        
        // Stop motion monitoring
        motionManager.stopDeviceMotionUpdates()
        isMonitoring = false
        
        // Stop breathing animation
        breathingView.layer.removeAllAnimations()
        breathingView.backgroundColor = UIColor(red: 194/255, green: 8/255, blue: 8/255, alpha: 1) // Reset to initial color
        
        // Log wake-up time if not already logged
        if wakeUpTime == nil {
            wakeUpTime = Date()
            logWakeUpTime()
        }
        
        // Save sleep data to Firebase
        saveSleepDataToFirebase()
    }
    
    func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func startColorTransition() {
        let darkRed = UIColor(red: 194/255, green: 8/255, blue: 8/255, alpha: 1)
        let lightRed = UIColor(red: 242/255, green: 78/255, blue: 78/255, alpha: 1)
        
        UIView.animate(withDuration: 3.0,
                       delay: 0,
                       options: [.autoreverse, .repeat, .allowUserInteraction],
                       animations: {
            self.breathingView.backgroundColor = lightRed
        }, completion: { _ in
            self.breathingView.backgroundColor = darkRed
        })
    }
    
    func stopColorTransition() {
        breathingView.layer.removeAllAnimations()
        breathingView.backgroundColor = UIColor(red: 194/255, green: 8/255, blue: 8/255, alpha: 1)
    }
    
    // MARK: - CoreMotion Functions
    func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion not available")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 0.5 // Update every 0.5 seconds
        
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motionData, error) in
            guard let self = self, let motionData = motionData else { return }
            
            // Detect motion
            let magnitude = abs(motionData.attitude.roll) + abs(motionData.attitude.pitch) + abs(motionData.attitude.yaw)
            
            if magnitude > self.motionThreshold && self.isMonitoring {
                let currentTime = Date()
                
                // Log first wake-up time
                if self.wakeUpTime == nil {
                    self.wakeUpTime = currentTime
                    self.logWakeUpTime()
                    self.saveSleepDataToFirebase()
                }
            }
        }
    }
    
    // MARK: - Firebase Functions
    func saveSleepDataToFirebase() {
        guard let userId = Auth.auth().currentUser?.uid,
              let bedtime = bedtime,
              let sleepTime = sleepTime,
              let wakeUpTime = wakeUpTime else {
            print("Missing sleep data")
            return
        }
        
        // Calculate duration in minutes
        let duration = wakeUpTime.timeIntervalSince(sleepTime) / 60
        
        // Get date key for the sleep session
        let calendar = Calendar.current
        let sleepDate = calendar.startOfDay(for: sleepTime)
        let dateKey = DateFormatter.yyyyMMdd.string(from: sleepDate)
        
        let db = Firestore.firestore()
        
        // Reference to the sleepData document for this date
        let dateRef = db.collection("users").document(userId)
            .collection("sleepData").document(dateKey)
        
        // Create sleep segment data
        let segmentData: [String: Any] = [
            "startTime": Timestamp(date: sleepTime),
            "endTime": Timestamp(date: wakeUpTime),
            "value": "CORE",  // Set to CORE sleep stage
            "stageType": 2,    // Numerical representation for CORE
            "duration": duration
        ]
        
        // Add to sleepSegments subcollection
        dateRef.collection("sleepSegments").addDocument(data: segmentData) { error in
            if let error = error {
                print("Error saving sleep segment: \(error.localizedDescription)")
                return
            }
            
            // Update total sleep duration for the day
            dateRef.setData([
                "startOfDay": Timestamp(date: sleepDate),
                "totalSleepDuration": FieldValue.increment(duration)
            ], merge: true) { error in
                if let error = error {
                    print("Error updating total sleep: \(error.localizedDescription)")
                } else {
                    print("Successfully updated total sleep duration")
                    self.updateStreakIfNeeded()
                }
            }
        }
    }
    
    private func updateStreakIfNeeded() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayKey = DateFormatter.yyyyMMdd.string(from: yesterday)
        
        db.collection("users").document(userId)
            .collection("sleepData").document(yesterdayKey).getDocument { snapshot, _ in
                guard let data = snapshot?.data(),
                      let totalSleep = data["totalSleepDuration"] as? Double else {
                    return
                }
                
                StreakManager.shared.updateStreak(userId: userId, totalSleep: totalSleep)
            }
    }
    
    // MARK: - Logging Functions
    func logBedtime() {
        guard let bedtime = bedtime else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        
        print("Bedtime logged at: \(formatter.string(from: bedtime))")
    }
    
    func logWakeUpTime() {
        guard let wakeUpTime = wakeUpTime else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        
        print("Wake-up time detected at: \(formatter.string(from: wakeUpTime))")
    }
    
    // MARK: - View Lifecycle
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAllPlayback()
    }
}

// MARK: - Collection View Delegate & Data Source
extension RedLightViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return playlists.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaylistCell", for: indexPath) as! PlaylistCollectionViewCell
        let playlist = playlists[indexPath.item]
        
        cell.configure(with: playlist)
        cell.playAction = { [weak self] in
            guard let self = self else { return }
            if self.audioPlayers.isEmpty {
                self.playPlaylist(playlist)
            } else {
                self.stopAllPlayback()
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let visibleIndex = Int(scrollView.contentOffset.x / scrollView.frame.width)
        currentPlaylistIndex = visibleIndex
        stopAllPlayback()
    }
}
