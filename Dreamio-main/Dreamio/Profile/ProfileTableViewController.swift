
import UIKit
import FirebaseAuth

class ProfileTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true) // Remove cell highlight after tap

        // Check if the Sign Out cell (3rd section, 4th row) is tapped
        if indexPath.section == 2 && indexPath.row == 3 { // Adjust if needed
            signOutUser()
        }
    }

    func signOutUser() {
        do {
            try Auth.auth().signOut()

            // Navigate to Login Page
            if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginSignup") // Replace with your actual login VC ID
                sceneDelegate.window?.rootViewController = loginVC
                sceneDelegate.window?.makeKeyAndVisible()
            }
        } catch let error {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
