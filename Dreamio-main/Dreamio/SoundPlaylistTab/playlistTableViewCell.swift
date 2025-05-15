import UIKit
import AVFoundation

protocol PlaylistCellDelegate: AnyObject {
    func removePlaylist(for cell: playlistTableViewCell)
    func renamePlaylist(for cell: playlistTableViewCell)
}

class playlistTableViewCell: UITableViewCell {

    @IBOutlet var playlistName: UILabel!
    @IBOutlet var playlistPlayButton: UIButton!
    @IBOutlet var playlistMenuButton: UIButton!

    var isPlaying: Bool = false  // Track if the playlist is playing
    weak var delegate: PlaylistCellDelegate?
    var audioPlayers: [AVAudioPlayer] = [] // Track players for all songs in the playlist
    
    // Play button action
    @IBAction func playButtonTapped(_ sender: UIButton) {
        if isPlaying {
            // Stop all audio playback
            stopAllPlayback()
            playlistPlayButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            isPlaying = false
            playlistPlayButton.tintColor = .systemTeal
        } else {
            // Play all songs in the playlist
            playAllSoundsInPlaylist()
            playlistPlayButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            isPlaying = true
            playlistPlayButton.tintColor = .systemTeal
        }
    }
    
    // Menu button action to show rename/remove options
    private func setupMenu() {
        let removeAction = UIAction(title: "Remove Playlist", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.removePlaylist(for: self)
        }

        let renameAction = UIAction(title: "Rename Playlist", image: UIImage(systemName: "pencil")) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.renamePlaylist(for: self)
        }

        let menu = UIMenu(title: "", options: .displayInline, children: [renameAction, removeAction])
        playlistMenuButton.menu = menu
        playlistMenuButton.showsMenuAsPrimaryAction = true
    }
    
    // Helper function to play all sounds in the playlist at once
    func playAllSoundsInPlaylist() {
        guard let playlistName = playlistName.text else { return }
        let tracks = DataModel1.getTracks(forPlaylistNamed: playlistName)
        
        // Play all tracks with their volumes
        for track in tracks {
            guard let music = track.music,
                  let fileName = music.fileName,
                  let url = Bundle.main.url(forResource: fileName, withExtension: nil)
            else { continue }
            
            if let audioPlayer = try? AVAudioPlayer(contentsOf: url) {
                audioPlayer.volume = track.volume // Use stored volume
                audioPlayers.append(audioPlayer)
                audioPlayer.play()
            }
        }
    }
    
    // Stop all audio playback
    func stopAllPlayback() {
        for player in audioPlayers {
            player.stop()
        }
        audioPlayers.removeAll()
    }
    
    // Helper function to get the URL of a song
    func getSoundURL(for fileName: String) -> URL {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: nil) else {
            fatalError("Sound file not found.")
        }
        return url
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupMenu()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
