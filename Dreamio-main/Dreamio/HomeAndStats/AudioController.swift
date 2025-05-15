import AVFoundation

class AudioController {
    
    static let shared = AudioController()
    
    private var audioPlayer: AVAudioPlayer?
    private var currentMusic: MusicEntity? // Using MusicEntity here
    
    // Play audio
    func playAudio(_ music: MusicEntity) {
        // Check if the same audio is already playing
        if let currentMusic = currentMusic, currentMusic.musicID == music.musicID, audioPlayer?.isPlaying == true {
            // Audio is already playing, no need to play again
            return
        }
        
        // If the same audio is not already playing, play the new audio
        if let fileURL = Bundle.main.url(forResource: music.fileName, withExtension: nil) {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
                audioPlayer?.play()
                currentMusic = music
            } catch {
                print("Error loading audio file: \(error.localizedDescription)")
            }
        }
    }
    
    // Pause audio
    func pause() {
        audioPlayer?.pause()
    }
    
    // Check if the audio is playing
    func isPlaying(_ music: MusicEntity) -> Bool {
        // Use musicID to check if the same music is playing
        return currentMusic?.musicID == music.musicID && audioPlayer?.isPlaying == true
    }
    
    // Stop audio (optional, if needed)
    func stop() {
        audioPlayer?.stop()
        currentMusic = nil
    }
}
