
import UIKit
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import FirebaseCore
import FirebaseFirestore

class RegisterViewController: UIViewController {
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    
    @IBOutlet weak var googleSignUpButton: UIButton!
    @IBOutlet weak var appleSignUpButton: UIButton!
    
    // Variable to store nonce for Apple Sign-In
    var currentNonce: String?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Actions
    
    @IBAction func registerButtonTapped(_ sender: UIButton) {
        guard let username = usernameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !username.isEmpty,
              let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !email.isEmpty,
              let password = passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !password.isEmpty,
              let confirmPassword = confirmPasswordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !confirmPassword.isEmpty else {
            showAlert(title: "Error", message: "All fields are required.")
            return
        }
        
        // Validate email format
        if !isValidEmail(email) {
            showAlert(title: "Error", message: "Please enter a valid email address.")
            return
        }
        
        // Validate password strength
        if password.count < 8 {
            showAlert(title: "Error", message: "Password must be at least 8 characters long.")
            return
        }
        
        // Check if passwords match
        if password != confirmPassword {
            showAlert(title: "Error", message: "Passwords do not match.")
            return
        }
        
        // Disable button and show loading indicator
        sender.isEnabled = false
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        
        // Register the user with Firebase Authentication
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
                sender.isEnabled = true
                activityIndicator.stopAnimating()
                activityIndicator.removeFromSuperview()
                
                if let error = error {
                    self.showAlert(title: "Error", message: error.localizedDescription)
                    return
                }
                
                // Save username to Firebase
                guard let user = result?.user else { return }
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = username
                changeRequest.commitChanges { error in
                    if let error = error {
                        self.showAlert(title: "Error", message: error.localizedDescription)
                    } else {
                        // Navigate to User Research after successful registration
                        self.navigateToUserResearchViewController()
                    }
                }
            }
        }
    
    @IBAction func googleSignUpTapped(_ sender: UIButton) {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { result, error in
            if let error = error {
                self.showAlert(title: "Error", message: error.localizedDescription)
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                self.showAlert(title: "Error", message: "Failed to get Google user data.")
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    self.showAlert(title: "Error", message: error.localizedDescription)
                    return
                }
                
                guard let authResult = authResult else {
                    self.showAlert(title: "Error", message: "No authentication result.")
                    return
                }
                
                // Check if the user is new
                let isNewUser = authResult.additionalUserInfo?.isNewUser ?? false
                let firebaseUser = authResult.user
                let db = Firestore.firestore()
                let userRef = db.collection("users").document(firebaseUser.uid)
                
                // Update Firestore with user data (merging so as not to overwrite other fields)
                userRef.setData([
                    "name": user.profile?.name ?? "Unknown",
                    "email": firebaseUser.email ?? "",
                    "uid": firebaseUser.uid
                ], merge: true) { error in
                    if let error = error {
                        print("Error updating Firestore: \(error.localizedDescription)")
                    } else {
                        print("User data updated in Firestore")
                    }
                    
                    // Navigate based on new/existing user status
                    if isNewUser {
                        self.navigateToUserResearchViewController()
                    } else {
                        self.navigateToTabBarController()
                    }
                }
            }
        }
    }
    
    @IBAction func appleSignUpTapped(_ sender: UIButton) {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authController = ASAuthorizationController(authorizationRequests: [request])
        authController.delegate = self
        authController.presentationContextProvider = self
        authController.performRequests()
    }
    
    // MARK: - Helper Methods
    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPredicate.evaluate(with: email)
    }

    private func navigateToTabBarController() {
        if let tabBarController = storyboard?.instantiateViewController(withIdentifier: "MainTabBarController") as? UITabBarController {
            tabBarController.modalPresentationStyle = .fullScreen
            present(tabBarController, animated: true, completion: nil)
        } else {
            print("Could not find a view controller with the identifier 'MainTabBarController'")
        }
    }
    
    // Helper function to generate nonce for Apple Sign-In
    private func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] = [
            "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
            "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
        ]
        var result = ""
        for _ in 0..<length {
            result.append(charset[Int(arc4random_uniform(UInt32(charset.count)))])
        }
        return result
    }
    
    private func navigateToUserResearchViewController() {
        if let userResearchVC = storyboard?.instantiateViewController(withIdentifier: "UserResearchViewController") as? UserResearchViewController {
            userResearchVC.modalPresentationStyle = .fullScreen
            present(userResearchVC, animated: true, completion: nil)
        } else {
            print("Could not find a view controller with the identifier 'UserResearchViewController'")
        }
    }
}

// MARK: - Apple Sign-In Delegates
extension RegisterViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let idToken = appleIDCredential.identityToken,
                  let tokenString = String(data: idToken, encoding: .utf8),
                  let nonce = appleIDCredential.state,
                  nonce == currentNonce else {
                self.showAlert(title: "Error", message: "Invalid response from Apple Sign-In.")
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: tokenString, rawNonce: nonce)
            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    self.showAlert(title: "Error", message: error.localizedDescription)
                    return
                }
                
                guard let user = result?.user else { return }
                
                let db = Firestore.firestore()
                let userRef = db.collection("users").document(user.uid)
                
                let userData: [String: Any] = [
                    "name": appleIDCredential.fullName?.givenName ?? "Unknown",
                    "email": appleIDCredential.email ?? "",
                    "createdAt": Timestamp(date: Date())
                ]
                
                userRef.setData(userData, merge: true) { error in
                    if let error = error {
                        self.showAlert(title: "Error", message: "Failed to save user data: \(error.localizedDescription)")
                    } else {
                        self.navigateToTabBarController()
                    }
                }
            }

        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        showAlert(title: "Error", message: error.localizedDescription)
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
