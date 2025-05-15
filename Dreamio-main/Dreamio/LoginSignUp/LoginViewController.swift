import UIKit
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import FirebaseCore
import FirebaseFirestore

class LoginViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Actions
    
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        guard let username = usernameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !username.isEmpty,
              let password = passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !password.isEmpty else {
            showAlert(title: "Error", message: "Please enter both username and password.")
            return
        }
        
        // Validate email format
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailTest.evaluate(with: username) else {
            showAlert(title: "Error", message: "Please enter a valid email address.")
            return
        }
        
        // Disable button and show activity indicator
        sender.isEnabled = false
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = view.center
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        
        // Firebase Email/Password Authentication
        Auth.auth().signIn(withEmail: username, password: password) { result, error in
            sender.isEnabled = true
            activityIndicator.stopAnimating()
            activityIndicator.removeFromSuperview()
            
            if let error = error {
                if let authError = error as NSError? {
                    switch authError.code {
                    case AuthErrorCode.userNotFound.rawValue:
                        self.showAlert(title: "Error", message: "No account found with this email.")
                    case AuthErrorCode.wrongPassword.rawValue:
                        self.showAlert(title: "Error", message: "Incorrect password. Please try again.")
                    default:
                        self.showAlert(title: "Error", message: authError.localizedDescription)
                    }
                } else {
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
                return
            }
            
            // Successful login
            self.navigateToTabBarController()
        }
    }
    
    @IBAction func googleSignInTapped(_ sender: UIButton) {
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
    
    @IBAction func appleSignInTapped(_ sender: UIButton) {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authController = ASAuthorizationController(authorizationRequests: [request])
        authController.delegate = self
        authController.presentationContextProvider = self
        authController.performRequests()
    }
    
    @IBAction func forgotPasswordTapped(_ sender: UIButton) {
        guard let email = usernameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty else {
            showAlert(title: "Error", message: "Please enter your email address to reset the password.")
            return
        }
        
        // Validate email format
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailTest.evaluate(with: email) else {
            showAlert(title: "Error", message: "Please enter a valid email address.")
            return
        }
        
        // Firebase password reset
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                self.showAlert(title: "Error", message: error.localizedDescription)
            } else {
                self.showAlert(title: "Success", message: "A password reset link has been sent to your email.")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title,
                                                message: message,
                                                preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    private func navigateToTabBarController() {
        if let tabBarController = storyboard?.instantiateViewController(withIdentifier: "MainTabBarController") as? UITabBarController {
            tabBarController.modalPresentationStyle = .fullScreen
            present(tabBarController, animated: true, completion: nil)
        } else {
            print("Could not find a view controller with the identifier 'MainTabBarController'")
        }
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

extension LoginViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let idToken = appleIDCredential.identityToken,
                  let tokenString = String(data: idToken, encoding: .utf8) else {
                self.showAlert(title: "Error", message: "Unable to fetch identity token.")
                return
            }
            
            let nonce = UUID().uuidString
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: tokenString,
                                                      rawNonce: nonce)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    self.showAlert(title: "Error", message: error.localizedDescription)
                    return
                }
                
                guard let authResult = authResult else {
                    self.showAlert(title: "Error", message: "No authentication result.")
                    return
                }
                
                let isNewUser = authResult.additionalUserInfo?.isNewUser ?? false
                let firebaseUser = authResult.user
                let db = Firestore.firestore()
                let userRef = db.collection("users").document(firebaseUser.uid)
                
                let fullName = "\(appleIDCredential.fullName?.givenName ?? "") \(appleIDCredential.fullName?.familyName ?? "")"
                    .trimmingCharacters(in: .whitespaces)
                
                userRef.setData([
                    "name": fullName.isEmpty ? "Unknown" : fullName,
                    "email": firebaseUser.email ?? "",
                    "uid": firebaseUser.uid
                ], merge: true) { error in
                    if let error = error {
                        print("Error updating Firestore: \(error.localizedDescription)")
                    } else {
                        print("User data updated in Firestore")
                    }
                    
                    if isNewUser {
                        self.navigateToUserResearchViewController()
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
