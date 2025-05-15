
import UIKit
import AVFAudio

class SoundInPlaylistCellTableViewCell: UITableViewCell {
    
    @IBOutlet weak var soundImageView: UIImageView!
    @IBOutlet weak var soundTitleLabel: UILabel!
    @IBOutlet weak var soundDescription: UILabel!
    @IBOutlet weak var RemoveButton: UIButton!
    @IBOutlet var volumeSlider: UISlider!
    
    var audioPlayer: AVAudioPlayer? // Add a reference to the audio player for each song

    // Handler closures for play button and volume slider
    var playButtonTappedHandler: (() -> Void)?
    var volumeSliderChangedHandler: ((Float) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        volumeSlider.value = 1.0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func playButtonTapped(_ sender: UIButton) {
        playButtonTappedHandler?()
    }
    
    @IBAction func volumeSliderChanged(_ sender: UISlider) {
        volumeSliderChangedHandler?(sender.value)
    }
}
