import CoreData
import UIKit

class DataModel1 {
    static let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    // MARK: - PlaylistTrack Operations
    static func addMusic(_ music: MusicEntity, toPlaylistNamed playlistName: String, volume: Float = 1.0) {
        guard let playlist = getPlaylist(named: playlistName) else { return }
        
        // Create a new PlaylistTrack
        let playlistTrack = PlaylistTrack(context: context)
        playlistTrack.volume = volume
        playlistTrack.music = music
        playlist.addToTracks(playlistTrack) // Add to playlist's tracks
        
        saveContext()
    }
    
    // MARK: - Music Operations
    static func getAllMusic() -> [MusicEntity] { // ADD THIS METHOD
        let fetchRequest: NSFetchRequest<MusicEntity> = MusicEntity.fetchRequest()
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching music: \(error)")
            return []
        }
    }
    
    static func removeTrack(_ track: PlaylistTrack, fromPlaylistNamed playlistName: String) {
        guard let playlist = getPlaylist(named: playlistName) else { return }
        playlist.removeFromTracks(track)
        context.delete(track)
        saveContext()
    }
    
    static func removeMusic(_ music: MusicEntity, fromPlaylistNamed playlistName: String) {
        guard let playlist = getPlaylist(named: playlistName),
              let tracks = playlist.tracks?.allObjects as? [PlaylistTrack]
        else { return }
        
        // Delete all PlaylistTrack entries linked to this music
        for track in tracks where track.music == music {
            context.delete(track)
        }
        saveContext()
    }
    
    // Fetch all tracks in a playlist
    static func getTracks(forPlaylistNamed name: String) -> [PlaylistTrack] {
        guard let playlist = getPlaylist(named: name),
              let tracks = playlist.tracks?.allObjects as? [PlaylistTrack]
        else { return [] }
        return tracks
    }
    
    // MARK: - Core Methods (Updated)
    static func getAllPlaylists() -> [PlaylistEntity] {
        let fetchRequest: NSFetchRequest<PlaylistEntity> = PlaylistEntity.fetchRequest()
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching playlists: \(error)")
            return []
        }
    }
    
    static func getPlaylist(named name: String) -> PlaylistEntity? {
        let fetchRequest: NSFetchRequest<PlaylistEntity> = PlaylistEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        do {
            return try context.fetch(fetchRequest).first
        } catch {
            print("Error fetching playlist: \(error)")
            return nil
        }
    }
    
    static func saveContext() {
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}
