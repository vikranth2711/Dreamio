
import UIKit
import AVFAudio
import FirebaseAnalytics

class BreathingViewController: BaseViewController, AVAudioPlayerDelegate {

    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    @IBOutlet weak var circleView: UIView!
    @IBOutlet weak var instructionLabel: UILabel!
    
    @IBOutlet weak var progressBar1: UIView!
    @IBOutlet weak var progressBar2: UIView!
    @IBOutlet weak var progressBar3: UIView!
    @IBOutlet weak var progressBar4: UIView!
    
    var audioPlayer: AVAudioPlayer?
    var currentInstruction: String?
    var remainingRepeatCount = 0
    var isPaused = false
    var exerciseStartTime: Date?  // Track when the exercise starts
    var totalTimeSpent: TimeInterval = 0  // Track the total time spent
    
    override func viewDidLoad() {
        super.viewDidLoad()
        circleView.alpha = 0
        resetProgressBars()
        instructionLabel.alpha = 0
        pauseButton.isHidden = true
        Analytics.setAnalyticsCollectionEnabled(true)
    }

    @IBAction func startButtonPressed(_ sender: Any) {
        startButton.isHidden = true
        pauseButton.isHidden = false

        circleView.transform = CGAffineTransform(scaleX: 0, y: 0)
        circleView.layer.cornerRadius = circleView.bounds.height / 2
        circleView.alpha = 1.0

        remainingRepeatCount = 4
        animateBreathingEffect()
        animateProgressBars()

        // Start tracking the time when exercise begins
        exerciseStartTime = Date()
    }
    
    @IBAction func pauseButtonPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Breathing Exercise", message: "Would you like to restart the exercise?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Restart", style: .destructive, handler: { _ in
            self.resetBreathingAnimation()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }

    func resetBreathingAnimation() {
        startButton.isHidden = false
        pauseButton.isHidden = true
        instructionLabel.alpha = 0
        circleView.alpha = 0
        resetProgressBars()
        audioPlayer?.stop()
        isPaused = false
        remainingRepeatCount = 0
        
        // Log time spent on the feature before resetting
        if let startTime = exerciseStartTime {
            totalTimeSpent = Date().timeIntervalSince(startTime)
            logFeatureUsageToFirebase(feature: "BreathingTab", duration: totalTimeSpent)
        }
    }

    func logFeatureUsageToFirebase(feature: String, duration: TimeInterval) {
        Analytics.logEvent("feature_usage", parameters: [
            "feature_name": "BreathingTab",
            "duration_seconds": totalTimeSpent
        ])
    }

    func playAudio(for instruction: String) {
        let fileName = instruction.lowercased()
        guard let audioURL = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
            print("Audio file not found: \(fileName)")
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            currentInstruction = instruction
        } catch {
            print("Error playing audio: \(error)")
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard let instruction = currentInstruction else { return }
        if instruction.lowercased() == "inhale" {
            startHoldPhase()
        } else if instruction.lowercased() == "hold" {
            startExhalePhase()
        } else if instruction.lowercased() == "exhale" {
            if remainingRepeatCount > 0 {
                remainingRepeatCount -= 1
                startInhalePhase()
            } else {
                resetBreathingAnimation()
            }
        }
    }

    func showInstruction(_ text: String) {
        instructionLabel.text = text
        instructionLabel.alpha = 1.0
        playAudio(for: text.lowercased()) // Play the audio corresponding to the instruction
        
        UIView.animate(withDuration: 0.5) {
            self.instructionLabel.alpha = 1.0
        }
    }

    func animateBreathingEffect() {
        startInhalePhase()
    }
    
    func startInhalePhase() {
        showInstruction("Inhale")
        UIView.animate(withDuration: 4.0, animations: {
            self.circleView.transform = CGAffineTransform(scaleX: 1, y: 1)
        })
    }
    
    func startHoldPhase() {
        showInstruction("Hold")
        UIView.animate(withDuration: 7.0, animations: {
            self.circleView.alpha = 0.99999
        })
    }
    
    func startExhalePhase() {
        showInstruction("Exhale")
        UIView.animate(withDuration: 8.0, animations: {
            self.circleView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
        }) { _ in
            self.circleView.alpha = 1.0
        }
    }

    func animateProgressBars() {
        let bars = [progressBar1, progressBar2, progressBar3, progressBar4]

        for (index, bar) in bars.enumerated() {
            bar?.alpha = 1.0
            bar?.backgroundColor = .systemCyan
            bar?.transform = CGAffineTransform(scaleX: 0, y: 1)
                
            UIView.animate(withDuration: 19.0, delay: Double(index) * 19.0, options: .curveLinear, animations: {
                bar?.transform = CGAffineTransform(scaleX: 1, y: 1)
            }, completion: { _ in
                if index == bars.count - 1 {
                    self.hideProgressBars()
                }
            })
        }
    }

    func hideProgressBars() {
        let bars = [progressBar1, progressBar2, progressBar3, progressBar4]
        for bar in bars {
            bar?.alpha = 0.0
        }
    }

    func resetProgressBars() {
        let bars = [progressBar1, progressBar2, progressBar3, progressBar4]
        for bar in bars {
            bar?.transform = CGAffineTransform(scaleX: 0, y: 1)
            bar?.alpha = 1.0
            bar?.backgroundColor = .systemCyan
        }
    }
    func didSelectSound(_ sound: MusicEntity) {
        AudioManager.shared.play(track: sound) // Use 'play(track:)' instead of 'playTrack(_:)'
    }

}
