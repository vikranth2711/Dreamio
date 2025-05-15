
import UIKit

class RedLightControlViewController: BaseViewController {

    @IBOutlet weak var redLightSwitch: UISwitch!
    
    @IBAction func didToggleRedLight(_ sender: UISwitch) {
        if sender.isOn {
                  // Code to enable red light mode
                  print("Red Light Mode: ON")
              } else {
                  // Code to disable red light mode
                  print("Red Light Mode: OFF")
              }
          }
    
    func didSelectSound(_ sound: MusicEntity) {
        AudioManager.shared.play(track: sound) // Use 'play(track:)' instead of 'playTrack(_:)'
    }

      }
