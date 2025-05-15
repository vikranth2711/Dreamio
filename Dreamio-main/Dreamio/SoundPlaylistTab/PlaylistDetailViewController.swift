import UIKit
import AVFoundation

class PlaylistDetailViewController: BaseViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var playlist: PlaylistEntity?
    var audioPlayers: [AVAudioPlayer] = [] // Track players for each song
    var playingSongIndex: Int? // Track the index of the song currently being played
    var playlistTracks: [PlaylistTrack] = [] // Changed to PlaylistTrack array
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        self.title = playlist?.name
        
        if let playlist = playlist {
            playlistTracks = DataModel1.getTracks(forPlaylistNamed: playlist.name ?? "")
        }
    }
    
    // MARK: - Play All Button
    @IBAction func playAllButtonTapped(_ sender: Any) {
        stopAllPlayback()
        
        for track in playlistTracks {
            guard let music = track.music,
                  let fileName = music.fileName,
                  let url = Bundle.main.url(forResource: fileName, withExtension: nil)
            else { continue }
            
            if let audioPlayer = try? AVAudioPlayer(contentsOf: url) {
                audioPlayer.volume = track.volume // Set volume from PlaylistTrack
                audioPlayers.append(audioPlayer)
                audioPlayer.play()
            }
        }
    }
    
    func stopAllPlayback() {
        for player in audioPlayers {
            player.stop()
        }
        audioPlayers.removeAll()
        playingSongIndex = nil
    }
    
//    func didSelectSound(_ sound: MusicEntity) {
//        AudioManager.shared.play(track: sound) // Use 'play(track:)' instead of 'playTrack(_:)'
//    }
    
    // MARK: - Play/Pause Individual Song
    @objc func playButtonTapped(_ sender: UIButton) {
        // Safely unwrap the playlist and sounds array
        guard let playlist = playlist,
              let tracks = playlist.tracks?.allObjects as? [PlaylistTrack] else { return }
              let soundsArray = tracks.compactMap { $0.music } // Extract MusicEntity from PlaylistTrack

        let songIndex = sender.tag
        // Ensure the index is valid
        guard songIndex < soundsArray.count else { return }
        
        let song = soundsArray[songIndex]
        
        // Check if the song being tapped is already playing
        if let currentIndex = playingSongIndex, currentIndex == songIndex {
            let player = audioPlayers[currentIndex]
            
            // Toggle play/pause
            if player.isPlaying {
                player.pause()
                sender.setImage(UIImage(systemName: "play.fill"), for: .normal)
            } else {
                player.play()
                sender.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            }
        } else {
            // Stop any currently playing songs
            stopAllPlayback()
            
            // Extract fileName from song and play the new song
            if let fileName = song.fileName,
               let audioPlayer = try? AVAudioPlayer(contentsOf: getSoundURL(for: song)) { // pass 'song' here
                audioPlayers.append(audioPlayer)
                audioPlayer.play()
                playingSongIndex = songIndex
                sender.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            }
        }
//        AudioManager.shared.play(track: song)
    }

    // Get sound file URL for the given MusicEntity (not just fileName)
    func getSoundURL(for song: MusicEntity) -> URL {
        // Ensure you handle the file name properly here
        guard let fileName = song.fileName else {
            fatalError("Sound file not found for song.")
        }
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: nil) else {
            fatalError("Sound file not found in bundle.")
        }
        return url
    }

    
    // MARK: - Remove Track
    @objc func removeSoundFromPlaylist(_ sender: UIButton) {
        let index = sender.tag
        guard index < playlistTracks.count else { return }
        
        let track = playlistTracks[index]
        DataModel1.removeTrack(track, fromPlaylistNamed: playlist?.name ?? "")
        playlistTracks.remove(at: index)
        tableView.reloadData()
    }

    
    // MARK: - Volume Slider
    @objc func volumeSliderChanged(_ sender: UISlider) {
        let index = sender.tag
        guard index < playlistTracks.count else { return }
        
        let track = playlistTracks[index]
        track.volume = sender.value
        DataModel1.saveContext() // Save volume change
    }
}

// MARK: - Table View DataSource and Delegate
extension PlaylistDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlistTracks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SoundInPlaylistCell", for: indexPath) as? SoundInPlaylistCellTableViewCell,
              let track = playlistTracks[indexPath.row].music
        else { return UITableViewCell() }
        
        // Configure with MusicEntity data
        cell.soundTitleLabel.text = track.title
        cell.soundDescription.text = track.descriptions
        cell.soundImageView.image = UIImage(named: track.image ?? "defaultImage")
        
        // Set volume from PlaylistTrack
        cell.volumeSlider.value = playlistTracks[indexPath.row].volume
        cell.volumeSlider.tag = indexPath.row
        cell.volumeSlider.addTarget(self, action: #selector(volumeSliderChanged(_:)), for: .valueChanged)
        
        // Remove button
        cell.RemoveButton.tag = indexPath.row
        cell.RemoveButton.addTarget(self, action: #selector(removeSoundFromPlaylist(_:)), for: .touchUpInside)
        
        return cell
    }
}

extension MusicEntity {
    public override var description: String {
        return descriptions ?? "Untitled Song"
    }
}

