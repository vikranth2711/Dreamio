
import UIKit

class BottomPlaybackView: UIView {
    
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var playPauseButton: UIButton!

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadViewFromNib()
        setupObservers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadViewFromNib()
        setupObservers()
    }

    private func loadViewFromNib() {
        let nib = UINib(nibName: "BottomPlaybackView", bundle: Bundle.main)
        guard let view = nib.instantiate(withOwner: self, options: nil).first as? UIView else {
            fatalError("Could not load BottomPlaybackView from nib")
        }
        view.frame = self.bounds
        addSubview(view)
    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: .audioDidStartPlaying, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: .audioStateChanged, object: nil)
    }

    @objc func updateUI() {
        guard let track = AudioManager.shared.currentTrack else { return }
        
        titleLabel.text = track.title
        artistLabel.text = track.descriptions // Make sure 'descriptions' holds artist data
        coverImageView.image = UIImage(named: track.image ?? "defaultImage") // Ensure this property exists
        
        let buttonImage = AudioManager.shared.isPlaying ? UIImage(systemName: "pause.fill") : UIImage(systemName: "play.fill")
        playPauseButton.setImage(buttonImage, for: .normal)
        
        self.isHidden = false // Ensure view is visible when a track starts playing
    }

    @IBAction func playPauseTapped(_ sender: UIButton) {
        AudioManager.shared.togglePlayPause()
        updateUI()
    }
}
