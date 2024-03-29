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

    lazy var signUp = UIButton(type: .system)
    lazy var orLable = UILabel()
    lazy var signInWithGoogle = UIButton(type: .system)
    lazy var signIn = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        // Do any additional setup after loading the view.
    }


    func setupUI() {
        // Logo
        let logoImage = UIImageView()
        logoImage.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        logoImage.image = UIImage(named: "appIcon")
        logoImage.center = CGPoint(x: view.center.x, y: view.center.y / 2 - 100)
        logoImage.tintColor = .systemGray
        logoImage.clipsToBounds = true
        logoImage.layer.cornerRadius = 50
        view.addSubview(logoImage)
        
        let appName = UILabel()
        appName.frame = CGRect(x: logoImage.frame.origin.x, y: logoImage.frame.maxY + 30, width: view.frame.width - 50, height: 30)
        appName.text = "ChatApp"
        appName.font = UIFont(name: "Gill Sans", size: 30)
        view.addSubview(appName)
        
        // SignUP
        signUp.setTitle("SignUp", for: .normal)
        signUp.addTarget(self, action: #selector(signUpAction), for: .touchUpInside)
        let signUpFrame = CGRect(x: 40, y: view.frame.width - 130, width: view.frame.width - 80, height: 40)
        signUp.frame = signUpFrame
        signUp.tintColor = .black
        signUp.layer.cornerRadius = 9.0
        signUp.layer.borderColor = UIColor.black.cgColor
        signUp.layer.borderWidth = 2.0
        
        view.addSubview(signUp)
        
        // seprator
        orLable.text = "OR"
        orLable.textColor = .lightGray
        orLable.frame = CGRect(x: 180, y: view.frame.width - 100 + 20, width: view.frame.width - 80, height: 40)
        view.addSubview(orLable)
        
        // login with Google Button
        signInWithGoogle.setTitle(" Login with Google", for: .normal)
        signInWithGoogle.setImage(UIImage(named: "google"), for: .normal)
        signInWithGoogle.addTarget(self, action: #selector(signInWithGoogleAction), for: .touchUpInside)
        let signInWithGoogleFrame = CGRect(x: 40, y: view.frame.width - 120 + 50 + 50, width: view.frame.width - 80, height: 40)
        signInWithGoogle.frame = signInWithGoogleFrame
        signInWithGoogle.tintColor = UIColor.black
        signInWithGoogle.layer.cornerRadius = 9.0
        signInWithGoogle.layer.borderColor = UIColor.black.cgColor
        signInWithGoogle.layer.borderWidth = 2.0
        
        view.addSubview(signInWithGoogle)
        
        // login Button
        signIn.setTitle("Login", for: .normal)
        signIn.addTarget(self, action: #selector(signInAction), for: .touchUpInside)
        let signInFrame = CGRect(x: 40, y: view.frame.width - 120 + 50 + 70 + 60, width: view.frame.width - 80, height: 40)
        signIn.frame = signInFrame
        signIn.tintColor = .black
        signIn.layer.cornerRadius = 9.0
        signIn.layer.borderColor = UIColor.black.cgColor
        signIn.layer.borderWidth = 2.0
        
        view.addSubview(signIn)
    }

    @objc func signUpAction(){
        let emailSignUPView = EmailSignUPViewController()
        navigationController?.pushViewController(emailSignUPView, animated: true)
    }
    
    @objc func signInWithGoogleAction() {
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
                                AlerUser().alertUser(viewController: self, title: "Error", message: error)
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
    
    @objc func signInAction(){
        let emailSignINView = EmailSignINViewController()
        navigationController?.pushViewController(emailSignINView, animated: true)
    }
}
