
import UIKit

class BaseViewController: UIViewController {
    
    let playbackView = BottomPlaybackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPlaybackView()
        NotificationCenter.default.addObserver(self, selector: #selector(updatePlaybackView), name: .playbackUpdated, object: nil)
    }
    
    private func setupPlaybackView() {
        playbackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playbackView)
        
        NSLayoutConstraint.activate([
            playbackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playbackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playbackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            playbackView.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        playbackView.isHidden = true
    }
    
    @objc func updatePlaybackView() {
        if AudioManager.shared.currentTrack != nil {
            playbackView.isHidden = false
            playbackView.updateUI()
        } else {
            playbackView.isHidden = true
        }
    }
}

extension Notification.Name {
    static let playbackUpdated = Notification.Name("playbackUpdated")
}
