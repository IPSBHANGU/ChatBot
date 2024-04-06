//
//  UserDetailController.swift
//  Chatbot
//
//  Created by Inderpreet Singh on 07/04/24.
//

import UIKit
import NVActivityIndicatorView
import FirebaseAuth

class UserDetailController: UIViewController {
    
    lazy var headerView = UIView()
    lazy var backButton = UIButton(type: .custom)
    lazy var userProfileImageView = UIImageView()
    lazy var userName = UILabel()
    lazy var userEmailLabel = UILabel()
    lazy var userJoinDate = UILabel()
    lazy var userUIDLable = UILabel()
    
    lazy var activityIndicator: NVActivityIndicatorView = {
        let frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        let indicator = NVActivityIndicatorView(frame: frame, type: .ballClipRotate, color: .blue, padding: nil)
        indicator.center = self.view.center
        indicator.center.y = self.view.frame.midY
        return indicator
    }()
    
    var userUID: String?
    var userDetails: AuthenticatedUser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchUserDetails()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupHeaderView()
        setupUI()
    }
    
    func fetchUserDetails(){
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        LoginModel().fetchUserDetails(userID: userUID ?? "") { user, error in
            if let error = error {
                AlerUser().alertUser(viewController: self, title: "Error", message: error.localizedDescription)
            }
            self.userDetails = user
            self.activityIndicator.stopAnimating()
            self.updateUserDetails()
        }
    }

    func setupHeaderView() {
        headerView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 90)
        headerView.backgroundColor = .white
        
        backButton.frame = CGRect(x: 24, y: 60, width: 24, height: 24)
        backButton.setImage(UIImage(systemName: "arrow.backward"), for: .normal)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backButton.tintColor = .black
        headerView.addSubview(backButton)
        view.addSubview(headerView)
    }
    
    func setupUI() {
        // Profile Image
        userProfileImageView.contentMode = .scaleAspectFit
        userProfileImageView.clipsToBounds = true
        userProfileImageView.frame = CGRect(x: (view.frame.width - 120) / 2, y: headerView.frame.maxY + 40, width: 120, height: 120)
        userProfileImageView.layer.cornerRadius = 60
        view.addSubview(userProfileImageView)
        
        // User Label
        userName.font = UIFont(name: "Rubik-SemiBold", size: 18)
        userName.numberOfLines = 5
        userName.frame = CGRect(x: 20, y: userProfileImageView.frame.maxY + 40, width: view.frame.width - 40, height: 30)
        view.addSubview(userName)
        
        // User Email Label
        userEmailLabel.numberOfLines = 0
        userEmailLabel.font = UIFont(name: "Rubik-Regular", size: 16)
        userEmailLabel.frame = CGRect(x: 20, y: userName.frame.maxY + 10, width: view.frame.width - 40, height: 0)
        view.addSubview(userEmailLabel)
        
        // User Join Date Label
        userJoinDate.numberOfLines = 0
        userJoinDate.font = UIFont(name: "Rubik-Regular", size: 16)
        userJoinDate.frame = CGRect(x: 20, y: userEmailLabel.frame.maxY + 10, width: view.frame.width - 40, height: 0)
        view.addSubview(userJoinDate)
        
        // User UID
        if userUID == Auth.auth().currentUser?.uid {
            userUIDLable.numberOfLines = 0
            userUIDLable.font = UIFont(name: "Rubik-Regular", size: 16)
            userUIDLable.frame = CGRect(x: 20, y: userJoinDate.frame.maxY + 10, width: view.frame.width - 40, height: 0)
            view.addSubview(userUIDLable)
        }
    }
    
    func updateUserDetails() {
        if let user = userDetails {
            // User Profile Image
            if let url = URL(string: user.photoURL ?? "") {
                userProfileImageView.kf.setImage(with: url)
            }
            
            // UserName
            userName.text = user.displayName
            
            // User Email
            let emailAttributedString = NSMutableAttributedString(string: "Email: ", attributes: [.font: UIFont(name: "Rubik-SemiBold", size: 16) ?? UIFont.boldSystemFont(ofSize: 16)])
            emailAttributedString.append(NSAttributedString(string: user.email ?? ""))
            userEmailLabel.attributedText = emailAttributedString
            userEmailLabel.sizeToFit() // Adjust label height based on content
            
            // User Join Date
            if let registeredDate = user.registeredDate {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .medium
                let formattedDate = dateFormatter.string(from: registeredDate)
                
                let joinDateAttributedString = NSMutableAttributedString(string: "Join Date: ", attributes: [.font: UIFont(name: "Rubik-SemiBold", size: 16) ?? UIFont.boldSystemFont(ofSize: 16)])
                joinDateAttributedString.append(NSAttributedString(string: formattedDate))
                userJoinDate.attributedText = joinDateAttributedString
                userJoinDate.sizeToFit() // Adjust label height based on content
            }
            
            // Update frames after setting content
            userEmailLabel.frame.size.height = heightForLabel(userEmailLabel)
            userJoinDate.frame.origin.y = userEmailLabel.frame.maxY + 10
            userJoinDate.frame.size.height = heightForLabel(userJoinDate)
            
            // User UID
            if userUID == Auth.auth().currentUser?.uid {
                let uidAttributedString = NSMutableAttributedString(string: "ID: ", attributes: [.font: UIFont(name: "Rubik-SemiBold", size: 16) ?? UIFont.boldSystemFont(ofSize: 16)])
                uidAttributedString.append(NSAttributedString(string: user.uid ?? ""))
                userUIDLable.attributedText = uidAttributedString
                userUIDLable.sizeToFit()
                userUIDLable.frame.origin.y = userJoinDate.frame.maxY + 10
                userUIDLable.frame.size.height = heightForLabel(userUIDLable)
            }
        }
    }
    
    @objc func backButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }

    func heightForLabel(_ label: UILabel) -> CGFloat {
        let maxSize = CGSize(width: label.frame.width, height: CGFloat.greatestFiniteMagnitude)
        let actualSize = label.sizeThatFits(maxSize)
        return actualSize.height
    }
}
