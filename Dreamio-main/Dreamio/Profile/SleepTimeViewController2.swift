
import UIKit

class SleepTimeViewController2: BaseViewController {
    @IBOutlet weak var bedTimeLabel: UILabel!
    
    @IBOutlet weak var wakeUpTimeLabel: UILabel!
    
      var bedTime: String = "10:00 PM" // Default Bed Time
      var wakeUpTime: String = "6:30 AM" // Default Wake Up Time

    
    
    @IBAction func editBedTimeTapped(_ sender: UIButton) {
        showTimePicker(for: "Bed Time")
    }
    
    @IBAction func editWakeUpTimeTapped(_ sender: UIButton) {
        showTimePicker(for: "Wake Up Time")
    }
    
    // MARK: - Helper Methods
      func showTimePicker(for type: String) {
          // Create the alert controller
          let alertController = UIAlertController(title: "Edit \(type)", message: "\n\n\n\n\n\n\n\n", preferredStyle: .alert)
          
          // Create and configure the date picker
          let datePicker = UIDatePicker()
          datePicker.datePickerMode = .time
          datePicker.preferredDatePickerStyle = .wheels
          datePicker.frame = CGRect(x: 0, y: 50, width: alertController.view.bounds.size.width - 20, height: 150)
          
          // Add the date picker to the alert
          alertController.view.addSubview(datePicker)
          
          // Add Save action
          let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
              // Format and retrieve selected time
              let formatter = DateFormatter()
              formatter.timeStyle = .short
              let selectedTime = formatter.string(from: datePicker.date)
              
              // Update the appropriate label and console
              if type == "Bed Time" {
                  self.bedTime = selectedTime
                  self.bedTimeLabel.text = self.bedTime
                  print("Updated Bed Time: \(self.bedTime)")
              } else if type == "Wake Up Time" {
                  self.wakeUpTime = selectedTime
                  self.wakeUpTimeLabel.text = self.wakeUpTime
                  print("Updated Wake Up Time: \(self.wakeUpTime)")
              }
          }
          
          // Add Cancel action
          let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
          
          // Add actions to the alert controller
          alertController.addAction(saveAction)
          alertController.addAction(cancelAction)
          
          // Present the alert controller
          self.present(alertController, animated: true, completion: nil)
      }
    
    func didSelectSound(_ sound: MusicEntity) {
        AudioManager.shared.play(track: sound) // Use 'play(track:)' instead of 'playTrack(_:)'
    }

  }
