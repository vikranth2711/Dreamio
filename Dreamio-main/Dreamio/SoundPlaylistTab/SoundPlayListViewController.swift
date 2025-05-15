import UIKit
import AVFoundation
import CoreData

class SoundPlayListViewController: BaseViewController, UISearchBarDelegate {

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var soundTableView: UITableView!
    @IBOutlet weak var playlistTableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!

    var playlistName: String?
    var soundsInPlaylist: [MusicEntity] = []

    var allSounds: [MusicEntity] = [] // Fetching MusicEntity instead of static music
    var filteredSounds: [MusicEntity] = []

    var allPlaylists: [PlaylistEntity] = [] // Fetching PlaylistEntity instead of static playlists
    var filteredPlaylists: [PlaylistEntity] = []

    var audioPlayer: AVAudioPlayer?
    var isPlaying: Bool = false
    
    var currentlyPlayingIndex: Int?

    override func viewDidLoad() {
        super.viewDidLoad()

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createPlaylistButtonTapped))
        self.navigationItem.rightBarButtonItem = addButton

        // Add music data to Core Data
        addMusicToCoreData()
        
        fetchMusicData()
        fetchPlaylistData()

        soundTableView.delegate = self
        soundTableView.dataSource = self
        playlistTableView.delegate = self
        playlistTableView.dataSource = self
        searchBar.delegate = self

        playlistTableView.isHidden = true
        soundTableView.isHidden = false
    }

    // MARK: - Fetch Music Data from Core Data
    func fetchMusicData() {
        allSounds = CoreDataManager.shared.fetchMusicData()
        filteredSounds = allSounds
        soundTableView.reloadData()
    }

    
    // Fetch Playlist data from Core Data
    func fetchPlaylistData() {
        allPlaylists = CoreDataManager.shared.fetchPlaylistsData() // Core Data fetch
        filteredPlaylists = allPlaylists
        playlistTableView.reloadData()
    }

    // MARK: - Add Music to Playlist
    // Handling a PlaylistEntity object for Core Data operations
    func addMusicToPlaylist(music: MusicEntity, playlist: PlaylistEntity) {
        DataModel1.addMusic(music, toPlaylistNamed: playlist.name ?? "", volume: 1.0)
        CoreDataManager.shared.saveContext()
    }
    
    func didSelectSound(_ sound: MusicEntity) {
        AudioManager.shared.play(track: sound) // Use 'play(track:)' instead of 'playTrack(_:)'
    }

    
    // MARK: - Segment Control Action
    @IBAction func segmentAction(_ sender: UISegmentedControl) {
        searchBar.text = ""
        searchBar.resignFirstResponder()

        switch sender.selectedSegmentIndex {
        case 0: // Sounds segment
            soundTableView.isHidden = false
            playlistTableView.isHidden = true
            filteredSounds = allSounds
            soundTableView.reloadData()
        case 1: // Playlists segment
            soundTableView.isHidden = true
            playlistTableView.isHidden = false
            filteredPlaylists = allPlaylists
            playlistTableView.reloadData()
        default:
            break
        }
    }

    // MARK: - Add to Playlist Action
    @objc func addToPlaylistButtonTapped(_ sender: UIButton) {
        let music = filteredSounds[sender.tag] // Get the selected music

        let context = CoreDataManager.shared.context
        let fetchRequest: NSFetchRequest<PlaylistEntity> = PlaylistEntity.fetchRequest()

        do {
            let playlists = try context.fetch(fetchRequest)

            let actionSheet = UIAlertController(title: "Add to Playlist", message: "Select a playlist", preferredStyle: .actionSheet)

            for playlist in playlists {
                let action = UIAlertAction(title: playlist.name, style: .default) { _ in
                    self.addMusicToPlaylist(music: music, playlist: playlist)
                }

                action.setValue(UIColor.systemTeal, forKey: "titleTextColor")
                actionSheet.addAction(action)
            }

            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            cancelAction.setValue(UIColor.systemTeal, forKey: "titleTextColor")
            actionSheet.addAction(cancelAction)

            present(actionSheet, animated: true, completion: nil)
        } catch {
            print("Error fetching playlists: \(error)")
        }
    }

    // MARK: - Play/Pause Sound Action

    @objc func playButtonTapped(_ sender: UIButton) {
        let selectedIndex = sender.tag
        let music = filteredSounds[selectedIndex]

        // Stop currently playing audio if any
        if let currentIndex = currentlyPlayingIndex, currentIndex != selectedIndex {
            stopAudio(at: currentIndex)
        }

        if isPlaying && currentlyPlayingIndex == selectedIndex {
            // Pause the current audio
            audioPlayer?.pause()
            sender.setImage(UIImage(systemName: "play.fill"), for: .normal)
            isPlaying = false
            currentlyPlayingIndex = nil
        } else {
            // Play the selected audio
            do {
                let url = getSoundURL(for: music)
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()

                // Update the button to show pause icon
                sender.setImage(UIImage(systemName: "pause.fill"), for: .normal)
                isPlaying = true
                currentlyPlayingIndex = selectedIndex
            } catch {
                print("Error loading sound file: \(error.localizedDescription)")
            }
        }

        // Update other visible cells' play/pause buttons
        updatePlayPauseButtons()
    }
    
    func stopAudio(at index: Int) {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentlyPlayingIndex = nil

        // Reset the play button for the stopped audio
        if let cell = soundTableView.cellForRow(at: IndexPath(row: index, section: 0)) as? soundTableViewCell {
            cell.soundPlayButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        }
    }
    
    func updatePlayPauseButtons() {
        for (index, _) in filteredSounds.enumerated() {
            let indexPath = IndexPath(row: index, section: 0)
            if let cell = soundTableView.cellForRow(at: indexPath) as? soundTableViewCell {
                let isCurrentlyPlaying = (index == currentlyPlayingIndex && isPlaying)
                let buttonImage = isCurrentlyPlaying ? "pause.fill" : "play.fill"
                cell.soundPlayButton.setImage(UIImage(systemName: buttonImage), for: .normal)
            }
        }
    }


    func getSoundURL(for music: MusicEntity) -> URL {
        guard let url = Bundle.main.url(forResource: music.fileName, withExtension: nil) else {
            fatalError("Sound file not found.")
        }
        return url
    }

    func createPlaylist(named name: String) {
        let context = CoreDataManager.shared.context
        let playlist = PlaylistEntity(context: context)
        playlist.name = name
        CoreDataManager.shared.saveContext()
        fetchPlaylistData() // Refresh playlist data
    }
    
    struct Playlist {
        var name: String
    }

    func convertToPlaylist(from entity: PlaylistEntity) -> Playlist {
        return Playlist(name: entity.name ?? "") // Map properties as needed
    }
    
    // MARK: - Prepare for Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowPlaylistDetail",
           let destinationVC = segue.destination as? PlaylistDetailViewController,
           let indexPath = playlistTableView.indexPathForSelectedRow {
            let selectedPlaylist = filteredPlaylists[indexPath.row]
            destinationVC.playlist = selectedPlaylist // Pass PlaylistEntity directly
        }
    }

    // MARK: - Create Playlist Action
    @objc func createPlaylistButtonTapped() {
        let alertController = UIAlertController(title: "Create Playlist", message: "Enter a name for your playlist", preferredStyle: .alert)

        alertController.addTextField { textField in
            textField.placeholder = "Playlist Name"
        }

        let createAction = UIAlertAction(title: "Create", style: .default) { [weak self] _ in
            if let playlistName = alertController.textFields?.first?.text, !playlistName.isEmpty {
                self?.createPlaylist(named: playlistName)
            }
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alertController.addAction(createAction)
        alertController.addAction(cancelAction)
        alertController.view.tintColor = .systemTeal

        present(alertController, animated: true, completion: nil)
    }

}

// MARK: - Table View DataSource and Delegate
extension SoundPlayListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == soundTableView {
            return filteredSounds.count
        } else if tableView == playlistTableView {
            return filteredPlaylists.count
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == soundTableView {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "SoundCell", for: indexPath) as? soundTableViewCell else {
                return UITableViewCell()
            }

            let music = filteredSounds[indexPath.row]

            // Configure the cell using the new method
            cell.configureCell(with: music)

            // Set up buttons with actions
            cell.addToPlaylistButton.tag = indexPath.row
            cell.addToPlaylistButton.addTarget(self, action: #selector(addToPlaylistButtonTapped(_:)), for: .touchUpInside)
            cell.soundPlayButton.tag = indexPath.row
            cell.soundPlayButton.addTarget(self, action: #selector(playButtonTapped(_:)), for: .touchUpInside)

            // Set the initial button image to "play.fill"
            cell.soundPlayButton.setImage(UIImage(systemName: "play.fill"), for: .normal)

            return cell
        } else if tableView == playlistTableView {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistCell", for: indexPath) as? playlistTableViewCell else {
                return UITableViewCell()
            }

            let playlist = filteredPlaylists[indexPath.row]

            // Configure playlist cell
            cell.playlistName.text = playlist.name
            cell.delegate = self
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == playlistTableView {
            let selectedPlaylist = filteredPlaylists[indexPath.row]
        }
    }
}

// MARK: - Search Bar Delegate
extension SoundPlayListViewController {
    @objc func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if segmentedControl.selectedSegmentIndex == 0 {
            if searchText.isEmpty {
                filteredSounds = allSounds
            } else {
                filteredSounds = allSounds.filter { $0.title?.lowercased().contains(searchText.lowercased()) ?? false }
            }
            soundTableView.reloadData()
        } else if segmentedControl.selectedSegmentIndex == 1 {
            if searchText.isEmpty {
                filteredPlaylists = allPlaylists
            } else {
                filteredPlaylists = allPlaylists.filter { $0.name?.lowercased().contains(searchText.lowercased()) ?? false }
            }
            playlistTableView.reloadData()
        }
    }
}

extension SoundPlayListViewController: PlaylistCellDelegate {
    func removePlaylist(for cell: playlistTableViewCell) {
        guard let indexPath = playlistTableView.indexPath(for: cell) else { return }
        let playlist = filteredPlaylists[indexPath.row]
        CoreDataManager.shared.delete(playlist)
        filteredPlaylists = CoreDataManager.shared.fetchPlaylistsData()
        playlistTableView.reloadData()
    }

    func renamePlaylist(for cell: playlistTableViewCell) {
        guard let indexPath = playlistTableView.indexPath(for: cell) else { return }
        let playlist = filteredPlaylists[indexPath.row]
        
        let alertController = UIAlertController(title: "Rename Playlist", message: "Enter a new name for the playlist", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.text = playlist.name
        }

        let renameAction = UIAlertAction(title: "Rename", style: .default) { _ in
            if let newName = alertController.textFields?.first?.text, !newName.isEmpty {
                playlist.name = newName
                CoreDataManager.shared.saveContext()
                self.filteredPlaylists = CoreDataManager.shared.fetchPlaylistsData()
                self.playlistTableView.reloadData()
            }
        }

        alertController.addAction(renameAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(alertController, animated: true, completion: nil)
    }
}
