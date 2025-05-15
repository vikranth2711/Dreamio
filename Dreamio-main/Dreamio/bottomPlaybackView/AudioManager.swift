
import Foundation
import AVFoundation

class AudioManager {
    static let shared = AudioManager()
    
    var currentTrack: MusicEntity?
    var audioPlayer: AVAudioPlayer?
    var isPlaying: Bool { audioPlayer?.isPlaying ?? false }
    
    private init() {}

    func play(track: MusicEntity) {
        guard let url = getSoundURL(for: track) else {
            print("Error: Sound file URL not found for track \(track.title ?? "Unknown")")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            currentTrack = track
            
            NotificationCenter.default.post(name: .audioDidStartPlaying, object: nil)
        } catch {
            print("Error playing audio: \(error)")
        }
    }

    func togglePlayPause() {
        guard let player = audioPlayer else { return }
        if player.isPlaying {
            player.pause()
        } else {
            player.play()
        }
        NotificationCenter.default.post(name: .audioStateChanged, object: nil)
    }

    private func getSoundURL(for song: MusicEntity) -> URL? {
        guard let fileName = song.fileName else { return nil }
        return Bundle.main.url(forResource: fileName, withExtension: nil)
    }
}

// Notifications for updates
extension Notification.Name {
    static let audioDidStartPlaying = Notification.Name("audioDidStartPlaying")
    static let audioStateChanged = Notification.Name("audioStateChanged")
}
