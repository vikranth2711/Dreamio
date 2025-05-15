
import UIKit

class PersonalInfoViewController: BaseViewController {
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var idTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    private var originalInfo: PersonalInfo?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadPersonalInfo()
        
        // Initially hide the password text by setting isSecureTextEntry to true
        passwordTextField.isSecureTextEntry = true
        
        // Add a tap gesture to dismiss the keyboard when tapping anywhere on the screen
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func loadPersonalInfo() {
        if let info = DataModel.shared.load() {
            originalInfo = info
            nameTextField.text = info.name
            idTextField.text = info.id
            passwordTextField.text = info.password
        } else {
            showAlert(title: "Error", message: "Failed to load personal information.")
        }
    }
    
    @IBAction func saveNameTapped(_ sender: UIButton) {
        if let name = nameTextField.text, !name.isEmpty {
            DataModel.shared.saveName(name)
            showAlert(title: "Success", message: "Name saved successfully!")
        } else {
            showAlert(title: "Error", message: "Please enter a valid name.")
        }
    }

    @IBAction func saveIDTapped(_ sender: UIButton) {
        if let id = idTextField.text, !id.isEmpty {
            DataModel.shared.saveID(id)
            showAlert(title: "Success", message: "ID saved successfully!")
        } else {
            showAlert(title: "Error", message: "Please enter a valid ID.")
        }
    }

    @IBAction func savePasswordTapped(_ sender: UIButton) {
        if let password = passwordTextField.text, !password.isEmpty {
            DataModel.shared.savePassword(password)
            showAlert(title: "Success", message: "Password saved successfully!")
        } else {
            showAlert(title: "Error", message: "Please enter a valid password.")
        }
    }

    @IBAction func togglePasswordVisibility(_ sender: UIButton) {
        passwordTextField.isSecureTextEntry.toggle()
        let buttonImage = passwordTextField.isSecureTextEntry ? "eye.slash" : "eye"
        sender.setImage(UIImage(systemName: buttonImage), for: .normal)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func didSelectSound(_ sound: MusicEntity) {
        AudioManager.shared.play(track: sound) // Use 'play(track:)' instead of 'playTrack(_:)'
    }

}
