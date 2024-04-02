//
//  ListChatViewController.swift
//  Chatbot
//
//  Created by Umang Kedan on 19/03/24.
//

import UIKit
import FirebaseAuth
import MASegmentedControl
import Kingfisher
import NVActivityIndicatorView
import SwiftyContextMenu

class ListChatViewController: UIViewController {
    
    // authResult
    var result:AuthDataResult?
    var authUser:AuthenticatedUser?
    
    // Start UIElements
    lazy var userAvatar = UIImageView()
    lazy var searchButton = UIButton(type: .system)
    lazy var editButton = UIButton(type: .system)
    lazy var chatType = MASegmentedControl()
    lazy var chatTable = UITableView()
    lazy var addButton = UIButton(type: .custom)
    var isButtonPressed:Bool?
    lazy var warning = UILabel()
    
    // SearchBar
    lazy var searchBar = UISearchBar()
    
    // ActivityIndicator
    var activityIndicatorView: NVActivityIndicatorView!
    
    var chatUserArray:[[String:Any]]?
    var filteredChatUserArray: [[String:Any]]?
    
    // Bool to switch to Group
    var is_Group:Bool = false    // Keep false as default is Chats
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let result = result {
            authUser = AuthenticatedUser(displayName: result.user.displayName, email: result.user.email, photoURL: result.user.photoURL?.absoluteString, uid: result.user.uid)
        }
        
        setupTableView()
        // Do any additional setup after loading the view.
    }
    
    override func viewIsAppearing(_ animated: Bool) {
        setupUI()
        setupActivityIndicator()
        
        if is_Group == false {
            fetchChatUsers()
        } else {
            fetchGroups()
        }
        if let chatUserArray = self.chatUserArray, !chatUserArray.isEmpty {
            warning.removeFromSuperview()
        }
    }
    
    func fetchChatUsers(){
        LoginModel().fetchConnectedUsers(authUser: authUser) { users, error in
            self.activityIndicatorView.startAnimating()
            if let error = error {
                AlerUser().alertUser(viewController: self, title: "Error", message: error)
                return
            }
            
            self.chatUserArray = users
            self.filteredChatUserArray?.removeAll()
            self.filteredChatUserArray = self.chatUserArray
            DispatchQueue.main.async {
                self.activityIndicatorView.stopAnimating()
                self.chatTable.reloadData()
                
                if let chatUserArray = self.chatUserArray, chatUserArray.isEmpty {
                    self.view.addSubview(self.warning)
                }
                
                if let chatUserArray = self.chatUserArray, !chatUserArray.isEmpty {
                    self.warning.removeFromSuperview()
                }
            }
        }
    }
    
    func fetchGroups(){
        GroupModel().fetchConnectedUsersInGroupChatInDB(userId: authUser?.uid ?? "") { group, error in
            self.activityIndicatorView.startAnimating()
            if let error = error {
                AlerUser().alertUser(viewController: self, title: "Error", message: error.localizedDescription)
            }
            self.chatUserArray = group
            self.filteredChatUserArray = self.chatUserArray
            DispatchQueue.main.async {
                self.activityIndicatorView.stopAnimating()
                self.chatTable.reloadData()
                
                if let chatUserArray = self.chatUserArray, chatUserArray.isEmpty {
                    self.view.addSubview(self.warning)
                }
                
                if let chatUserArray = self.chatUserArray, !chatUserArray.isEmpty {
                    self.warning.removeFromSuperview()
                }
            }
        }
    }
    
    func setupUI(){
        // UI Elements
        userAvatar.contentMode = .scaleAspectFit
        userAvatar.clipsToBounds = true
        let rect = CGRect(x: 24, y: 52, width: 32, height: 32)
        userAvatar.layer.cornerRadius = min(rect.width, rect.height) / 2.0
        userAvatar.frame = rect
        userAvatar.kf.setImage(with: URL(string: authUser?.photoURL ?? ""))
        view.addSubview(userAvatar)
        
        editButton.setImage(UIImage(systemName: "slider.horizontal.3"), for: .normal)
        editButton.alpha = 1
        editButton.tintColor = .black
        editButton.frame = CGRect(x: view.frame.width - 24 - 23, y: userAvatar.frame.origin.y, width: 24, height: 24)
        
        searchButton.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        searchButton.alpha = 1
        searchButton.tintColor = .black
        searchButton.frame = CGRect(x: editButton.frame.maxX - editButton.frame.width - 44, y: editButton.frame.origin.y, width: 24, height: 24)
        searchButton.addTarget(self, action: #selector(searchAction), for: .touchUpInside)
        view.addSubview(searchButton)
        
        let logout = UIAction(title: "Logout", image: UIImage(systemName: "xmark")) { _ in
            self.signOutButton()
        }
        
        let menu = UIMenu(title: "", children: [logout])
        editButton.showsMenuAsPrimaryAction = true
        editButton.menu = menu
        view.addSubview(editButton)

        chatType.frame = CGRect(x: 24, y: 112, width: 184, height: 32)
        chatType.addTarget(self, action: #selector(chatSelectorType(_:)), for: .valueChanged)
        chatType.itemsWithText = true
        chatType.fillEqually = true
        chatType.bottomLineThumbView = true
        chatType.setSegmentedWith(items: ["Chats", "Groups"])
        chatType.padding = -4
        chatType.textColor = .gray
        chatType.titlesFont = UIFont(name: "Rubik-Regular", size: 20)
        chatType.selectedTextColor = .black
        chatType.thumbViewColor = UIColorHex().hexStringToUIColor(hex: "#5AD7FF")
        chatType.segmentedBackGroundColor = .systemGray6
        chatType.selectedSegmentIndex = 0
        view.addSubview(chatType)
        
        chatTable.frame = CGRect(x: 0, y: 180, width: view.frame.width, height: view.frame.height + 32)
        
        // Add TableView to View
        view.addSubview(chatTable)
        
        // addButton
        addButton.frame = CGRect(x: 296, y: view.frame.maxY - 100 , width: 56, height: 56)
        addButton.setImage(UIImage(systemName: "message.fill"), for: .normal)
        addButton.backgroundColor = UIColorHex().hexStringToUIColor(hex: "#3780C2")
        addButton.layer.cornerRadius = 28
        addButton.tintColor = .white
        addButton.addTarget(self, action: #selector(addButtonAction(_:)), for: .touchUpInside)

        view.addSubview(addButton)
        
        warning.text = "No Conversations Found! Add Users to Start a Conversation"
        warning.numberOfLines = 0
        warning.font = UIFont(name: "Rubik-Regular", size: 18)
        warning.textColor = .placeholderText
        warning.frame = CGRect(x: 24, y: self.view.frame.midY, width: self.view.frame.width - 48, height: 50)
    }
    
    @objc func addButtonAction(_ sender: UIButton) {
        let addUsersView = AddUsersViewController()
        addUsersView.authUser = authUser
        addUsersView.is_Group = is_Group
        let navController = UINavigationController(rootViewController: addUsersView)
        self.present(navController, animated: true, completion: nil)
    }
    
    func setupTableView(){
        chatTable.delegate = self
        chatTable.dataSource = self
        chatTable.backgroundColor = .systemGray6
        chatTable.register(UINib(nibName: "ListChatTableViewCell", bundle: .main), forCellReuseIdentifier: "listChatTableView")
    }
    
    func setupActivityIndicator(){
        activityIndicatorView = NVActivityIndicatorView(frame: CGRect(x: view.frame.midX, y: view.frame.midY, width: 40, height: 40), type: .ballClipRotate, color: .blue, padding: nil)
        activityIndicatorView.center = view.center
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
        chatType.alpha = 0
        searchBar.alpha = 1
        searchBar.frame = CGRect(x: 24, y: 120, width: view.frame.width - 44, height: 40)
        searchBar.delegate = self
        searchBar.backgroundColor = .systemGray6
        searchBar.searchBarStyle = .minimal
        searchBar.layer.cornerRadius = 10
        searchBar.showsCancelButton = true
        searchBar.searchTextField.clearButtonMode = .never
        view.addSubview(searchBar)
    }
    
    @objc func chatSelectorType(_ sender: UISegmentedControl) {
        switch chatType.selectedSegmentIndex
        {
        case 0:
            is_Group = false
            chatUserArray?.removeAll()
            filteredChatUserArray?.removeAll()
            fetchChatUsers()
            showActivityIndicatorView()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.hideActivityIndicatorView()
            }
            chatTable.reloadData()
            
        case 1:
            is_Group = true
            showActivityIndicatorView()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.hideActivityIndicatorView()
            }
            chatUserArray?.removeAll()
            filteredChatUserArray?.removeAll()
            fetchGroups()
            chatTable.reloadData()
            
        default:
            break;
        }
        // MARK: TO-DO Change with database CallBack
    }
}

extension ListChatViewController:UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredChatUserArray?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "listChatTableView", for: indexPath) as? ListChatTableViewCell else {
            return UITableViewCell()
        }
        
        if is_Group == true {
            if let chatUserArray = filteredChatUserArray, indexPath.row < chatUserArray.count {
                let user = chatUserArray[indexPath.row]
                let groupName = user["groupName"] as? String ?? ""
                let conversationID = user["conversationID"] as? String ?? ""
                
                // Get the last message text
                GroupModel().observeGroupMessages(conversationID: conversationID, currentUserID: authUser?.uid ?? "") { messages in
                    if let lastMessage = messages.last {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "h:mm a"
                        let dateString = formatter.string(from: lastMessage.sentDate)
                        
                        let lastMessageText: String
                        switch lastMessage.kind {
                        case .text(let text):
                            lastMessageText = text
                        default:
                            lastMessageText = "Unsupported message type"
                        }
                        
                        // make my life more complex, use group avatar as latest msg by user's svtar
                        let photoURL = lastMessage.senderAvtar
                        
                        cell.setCellData(userImage: photoURL, username: groupName, userRecentMeassage: lastMessageText, meassageTime: dateString)
                    }
                }
            }
        } else {
            if let chatUserArray = filteredChatUserArray, indexPath.row < chatUserArray.count {
                let user = chatUserArray[indexPath.row]
                
                let username = user["displayName"] as? String ?? ""
                let avtarURL = user["photoURL"] as? String ?? ""
                let senderUID = user["uid"] as? String ?? ""
                let conversationID = ChatModel().generateConversationID(user1ID: authUser?.uid ?? "", user2ID: senderUID)
                
                // Get the last message text
                ChatModel().observeMessages(conversationID: conversationID, currentUserID: self.authUser?.uid ?? "", otherUserID: senderUID) { messages in
                    if let lastMessage = messages.last {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "h:mm a"
                        let dateString = formatter.string(from: lastMessage.sentDate)
                        
                        let lastMessageText: String
                        switch lastMessage.kind {
                        case .text(let text):
                            lastMessageText = text
                        default:
                            lastMessageText = "Unsupported message type"
                        }
                        
                        cell.setCellData(userImage: avtarURL, username: username, userRecentMeassage: lastMessageText, meassageTime: dateString)
                    }
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if is_Group == true {
            let chatController = GroupChatController()
            if let chatUserArray = filteredChatUserArray, indexPath.row < chatUserArray.count {
                let group = chatUserArray[indexPath.row]
                let groupName = group["groupName"] as? String ?? ""
                let conversationID = group["conversationID"] as? String ?? ""
                chatController.authUser = authUser
                chatController.groupName = groupName
                chatController.conversationID = conversationID
                navigationController?.pushViewController(chatController, animated: true)
            }
        } else {
            let chatController = ChatController()
            if let chatUserArray = filteredChatUserArray, indexPath.row < chatUserArray.count {
                let user = chatUserArray[indexPath.row]
                
                let username = user["displayName"] as? String ?? ""
                let userphoto = user["photoURL"] as? String ?? ""
                let senderUID = user["uid"] as? String ?? ""
                let conversationID = user["conversationID"] as? String ?? ""
                chatController.authUser = authUser
                chatController.senderUserName = username
                chatController.senderPhotoURL = userphoto
                chatController.senderUID = senderUID
                chatController.conversationID = conversationID
                navigationController?.pushViewController(chatController, animated: true)
            }
        }
    }
    
}

extension ListChatViewController:UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredChatUserArray = chatUserArray
        } else {
            filteredChatUserArray = (chatUserArray ?? []).filter { user in
                let username = user["displayName"] as? String ?? ""
                return username.lowercased().contains(searchText.lowercased())
            }
        }
        chatTable.reloadData()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        filteredChatUserArray = chatUserArray
        searchBar.alpha = 0
        chatType.alpha = 1
        chatTable.reloadData()
        searchBar.resignFirstResponder()
        searchBar.removeFromSuperview()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

}
