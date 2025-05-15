
import UIKit

class soundTableViewCell: UITableViewCell {

    @IBOutlet var soundImage: UIImageView!
    @IBOutlet var soundTitle: UILabel!
    @IBOutlet var soundDescription: UILabel!
    @IBOutlet var soundPlayButton: UIButton!
    @IBOutlet var addToPlaylistButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Configure the appearance of the soundImage
        soundImage.layer.cornerRadius = 8
        soundImage.clipsToBounds = true

        // Configure the soundTitle label
        soundTitle.font = UIFont.boldSystemFont(ofSize: 16)
        soundTitle.textColor = .label

        // Configure the soundDescription label
        soundDescription.font = UIFont.systemFont(ofSize: 14)
        soundDescription.textColor = .secondaryLabel
        soundDescription.numberOfLines = 2 // Limit to 2 lines for a cleaner look

        // Configure buttons' appearance
        soundPlayButton.tintColor = .systemTeal
        addToPlaylistButton.tintColor = .systemTeal
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Optional: Change the background color when the cell is selected
        contentView.backgroundColor = selected ? UIColor.systemGray5 : UIColor.clear
    }

    // Method to configure the cell with music data
    func configureCell(with music: MusicEntity) {
        soundTitle.text = music.title ?? "Unknown Title"
        soundDescription.text = music.descriptions ?? "No description available" // Use descriptions here
        if let imageName = music.image, let image = UIImage(named: imageName) {
            soundImage.image = image
        } else {
            soundImage.image = UIImage(named: "defaultImage") // Use a placeholder image
        }
    }
}
