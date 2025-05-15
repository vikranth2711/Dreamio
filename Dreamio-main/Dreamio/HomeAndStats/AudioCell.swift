import UIKit

class AudioCell: UICollectionViewCell {
    
    static let identifier = "AudioCell"
    
    private var imageView: UIImageView!
    private var playButton: UIButton!
    var music: MusicEntity?
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // Configure Image View
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 10
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        
        // Configure Play Button
        playButton = UIButton(type: .system)
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.tintColor = .white
        playButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        playButton.layer.cornerRadius = 15
        playButton.clipsToBounds = true
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        contentView.addSubview(playButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            // Image View Constraints
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // Play Button Constraints
            playButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            playButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            playButton.widthAnchor.constraint(equalToConstant: 30),
            playButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Configure Cell
    func configure(with music: MusicEntity) {
        self.music = music
        imageView.image = UIImage(named: music.image!)
    }
    
    // MARK: - Play Button Action
    @objc func playButtonTapped() {
        guard let music = music else { return }
        
        let audioController = AudioController.shared
        if audioController.isPlaying(music) {
            audioController.pause()
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        } else {
            audioController.playAudio(music)
            playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        }
    }
}
