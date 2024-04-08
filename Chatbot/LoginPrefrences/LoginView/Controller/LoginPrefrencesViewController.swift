//
//  LoginPrefrencesViewController.swift
//  Chatbot
//
//  Created by Umang Kedan on 20/03/24.
//

import UIKit
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

class LoginPrefrencesViewController: UIViewController {
    
    @IBOutlet weak var titleLable: UILabel!
    @IBOutlet var orLabel: UILabel!
    @IBOutlet var signInButton: UIButton!
    @IBOutlet var googleSignInButton: UIButton!
    @IBOutlet var signUpButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupFonts()
    }
    
    func setupFonts(){
        titleLable.text = "ChatApp"
        titleLable.font = UIFont(name: "Gill Sans", size: 30)
    }
    
    @IBAction func signUpaction(_ sender: Any) {
        let emailSignUPView = EmailSignUPViewController()
        navigationController?.pushViewController(emailSignUPView, animated: true)
    }
    
    @IBAction func googleSignInButtonAction(_ sender: Any) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        GoogleAuth().signIN(viewController: self) { isSucceeded, data, error in
            if let error = error {
                AlerUser().alertUser(viewController: self, title: "Google SignIn", message: error)
                return
            }
            if isSucceeded == true {
                guard let user = data?.user, let idToken = user.idToken?.tokenString else {
                    print("line 90 @LoginPrefrencesViewController else block")
                    return
                }
                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
                
                Auth.auth().signIn(with: credential) { result, error in
                    if let error = error {
                        AlerUser().alertUser(viewController: self, title: "Error", message: error.localizedDescription)
                    } else {
                        LoginModel().addUsersToDb(user: result?.user) { isSucceeded, error in
                            if let error = error {
                                switch error {
                                case .userAlreadyExists:
                                    let listChatView = ListChatViewController()
                                    listChatView.result = result
                                    self.navigationController?.pushViewController(listChatView, animated: true)
                                default:
                                    AlerUser().alertUser(viewController: self, title: "Error", message: "\(error)")
                                }
                            } else if isSucceeded {
                                /*
                                 * At this point User is Authenticated
                                 * move to next View
                                 */
                                let listChatView = ListChatViewController()
                                // pass whole result
                                listChatView.result = result
                                self.navigationController?.pushViewController(listChatView, animated: true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func loginAction(_ sender: Any) {
        let emailSignINView = EmailSignINViewController()
        navigationController?.pushViewController(emailSignINView, animated: true)
    }
    
}
