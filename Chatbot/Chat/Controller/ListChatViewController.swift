//
//  ListChatViewController.swift
//  Chatbot
//
//  Created by Inderpreet Singh on 19/03/24.
//

import UIKit
import FirebaseAuth
import MASegmentedControl
import Kingfisher
import NVActivityIndicatorView

class ListChatViewController: UIViewController {
    
    // authResult
    var result:AuthDataResult?
    var authUser:User?
    
    // Start UIElements
    let userAvatar = UIImageView()
    let searchButton = UIButton(type: .system)
    let editButton = UIButton(type: .system)
    let chatType = MASegmentedControl()
    let chatTable = UITableView()
    
    // ActivityIndicator
    var activityIndicatorView: NVActivityIndicatorView!
    
    // MARK: TO-DO Change with database CallBack
    let chatUserArray = ["Chat 1", "Chat 2", "Chat 3", "Chat 4", "Chat 5"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let result = result {
            authUser = result.user
        }
        setupUI()
        setupTableView()
        // Do any additional setup after loading the view.
    }
    
    func setupUI(){
        // UI Elements
        userAvatar.contentMode = .scaleAspectFit
        userAvatar.clipsToBounds = true
        let rect = CGRect(x: 20, y: 55, width: 35, height: 35)
        userAvatar.layer.cornerRadius = min(rect.width, rect.height) / 2.0
        userAvatar.frame = rect
        userAvatar.kf.setImage(with: authUser?.photoURL)
        view.addSubview(userAvatar)
        
        searchButton.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        searchButton.alpha = 1
        searchButton.tintColor = .black
        searchButton.frame = CGRect(x: view.frame.width - 70, y: 50, width: 40, height: 44)
        searchButton.addTarget(self, action: #selector(searchAction), for: .touchUpInside)
        view.addSubview(searchButton)
        
        editButton.setImage(UIImage(systemName: "slider.horizontal.3"), for: .normal)
        editButton.alpha = 1
        editButton.tintColor = .black
        editButton.frame = CGRect(x: view.frame.width - 30, y: 50, width: 40, height: 44)
        
        let logout = UIAction(title: "Logout", image: UIImage(systemName: "xmark")) { _ in
            self.signOutButton()
        }
        
        let menu = UIMenu(title: "", children: [logout])
        editButton.showsMenuAsPrimaryAction = true
        editButton.menu = menu
        view.addSubview(editButton)

        chatType.frame = CGRect(x: 20, y: 120, width: view.frame.width - 90, height: 40)
        chatType.addTarget(self, action: #selector(chatSelectorType(_:)), for: .valueChanged)
        chatType.itemsWithText = true
        chatType.fillEqually = true
        chatType.bottomLineThumbView = true
        chatType.setSegmentedWith(items: ["Inbox", "Meassages"])
        chatType.padding = 2
        chatType.textColor = .gray
        chatType.selectedTextColor = .black
        chatType.thumbViewColor = .cyan
        chatType.segmentedBackGroundColor = .systemGray6
        chatType.selectedSegmentIndex = 0
        view.addSubview(chatType)
        
        chatTable.frame = CGRect(x: 0, y: 190, width: view.frame.width, height: view.frame.height)
        
        // Add TableView to View
        view.addSubview(chatTable)
    }
    
    func setupTableView(){
        chatTable.delegate = self
        chatTable.dataSource = self
        chatTable.backgroundColor = .systemGray6
        chatTable.register(UINib(nibName: "ListChatTableViewCell", bundle: .main), forCellReuseIdentifier: "listChatTableView")
        activityIndicatorView = NVActivityIndicatorView(frame: CGRect(x: chatTable.frame.midX, y: chatTable.frame.midY, width: 40, height: 40), type: .ballClipRotate, color: .blue, padding: nil)
        activityIndicatorView.center = chatTable.center
        chatTable.addSubview(activityIndicatorView)
        activityIndicatorView.isHidden = true
    }
    
    func showActivityIndicatorView() {
        activityIndicatorView.startAnimating()
        activityIndicatorView.isHidden = false
    }

    func hideActivityIndicatorView() {
        activityIndicatorView.stopAnimating()
        activityIndicatorView.isHidden = true
    }
    
    func signOutButton() {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            self.navigationController?.popViewController(animated: true)
        } catch let signOutError as NSError {
            AlerUser().alertUser(viewController: self, title: "Error", message: "Error while Loging out user ERROR : \(signOutError)")
        }
    }
    
    @objc func searchAction(){
        // MARK: TO-DO Change with database CallBack
    }
    
    @objc func chatSelectorType(_ sender: UISegmentedControl) {
        switch chatType.selectedSegmentIndex
        {
        case 0:
            print("Inbox")
            showActivityIndicatorView()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.hideActivityIndicatorView()
            }
            
        case 1:
            print("meassages")
            showActivityIndicatorView()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.hideActivityIndicatorView()
            }
            
        default:
            break;
        }
        // MARK: TO-DO Change with database CallBack
    }
}

extension ListChatViewController:UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatUserArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "listChatTableView", for: indexPath) as? ListChatTableViewCell else {
            return UITableViewCell()
        }
        
        let user = chatUserArray[indexPath.row]
        
        // timepass
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let currentTime = dateFormatter.string(from: Date())
        
        cell.setCellData(userImage: nil, username: user, userRecentMeassage: "Placeholder", meassageTime: currentTime)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chatController = ChatController()
        chatController.authUser = authUser
        chatController.displayUserName = chatUserArray[indexPath.row]
        navigationController?.pushViewController(chatController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
