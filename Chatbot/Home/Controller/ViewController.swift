//
//  ViewController.swift
//  Chatbot
//
//  Created by Inderpreet Singh on 18/03/24.
//

import UIKit
import FirebaseCore
import GoogleSignIn
import FirebaseAuth
import NVActivityIndicatorView

class ViewController: UIViewController {
    
    // ActivityIndicator
    var activityIndicatorView: NVActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationController()
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        setupActivityIndicator()
        checkIfUserAvailable()
    }
    
    func setupNavigationController(){
        navigationController?.isNavigationBarHidden = true
    }
    
    func setupActivityIndicator(){
        activityIndicatorView = NVActivityIndicatorView(frame: CGRect(x: view.frame.midX, y: view.frame.midY, width: 40, height: 40), type: .ballClipRotate, color: .blue, padding: nil)
        activityIndicatorView.center = view.center
        view.addSubview(activityIndicatorView)
        activityIndicatorView.isHidden = true
    }
    
    func checkIfUserAvailable(){
        activityIndicatorView.startAnimating()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let user = Auth.auth().currentUser
            if user?.uid != nil {
                /*
                 * At this point User is Authenticated
                 * move to next View
                 */
                let listChatView = ListChatViewController()
                // pass whole result
                listChatView.authUser = user
                self.navigationController?.pushViewController(listChatView, animated: true)
            } else {
                let loginPrefrencesView = LoginPrefrencesViewController()
                self.navigationController?.pushViewController(loginPrefrencesView, animated: true)
            }
        }
    }
}

