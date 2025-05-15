
import UIKit

class NotificationsViewController: BaseViewController {

    @IBOutlet weak var allowNotificationsSwitch: UISwitch!
    
    @IBOutlet weak var showPreviewsSwitch: UISwitch!
    
    @IBAction func allowNotificationsSwitch(_ sender: UISwitch) {
        if sender.isOn {
                   print("Allow Notifications Switch is ON")
               } else {
                   print("Allow Notifications Switch is OFF")
               }
    }


    
    @IBAction func showPreviewsSwitch(_ sender: UISwitch) {
        if sender.isOn {
                   print("Show Previews Switch is ON")
               } else {
                   print("Show Previews Switch is OFF")
               }
           }
    }
    
   
