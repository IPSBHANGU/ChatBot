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
    
        setupUI()
        setupActivityIndicator()
        checkIfUserAvailable()
    }
    
    func setupNavigationController(){
        navigationController?.isNavigationBarHidden = true
    }
    
    func setupUI(){
        let logoImage = UIImageView()
        logoImage.frame = CGRect(x: 0, y: 0, width: 150, height: 150)
        logoImage.image = UIImage(named: "appIcon")
        logoImage.layer.cornerRadius = 75
        logoImage.clipsToBounds = true
        logoImage.center = CGPoint(x: view.center.x, y: view.center.y - 100)
        view.addSubview(logoImage)
        
        let appName = UILabel()
        appName.frame = CGRect(x: logoImage.frame.origin.x + 40, y: logoImage.frame.maxY + 10, width: view.frame.width - 50, height: 30)
        appName.text = "ChatApp"
        appName.font = UIFont(name: "Gill Sans", size: 30)
        view.addSubview(appName)
    }
    
    func setupActivityIndicator(){
        activityIndicatorView = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40), type: .ballClipRotate, color: .blue, padding: nil)
        activityIndicatorView.center = view.center
        activityIndicatorView.center.y = view.center.y + 80
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

