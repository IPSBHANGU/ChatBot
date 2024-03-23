//
//  AddUsersViewController.swift
//  Chatbot
//
//  Created by Inderpreet Singh on 23/03/24.
//

import UIKit
import FirebaseAuth
import NVActivityIndicatorView

class AddUsersViewController: UIViewController {

    lazy var usersTable = UITableView()
    
    var authUser:User?
    var chatUserArray:[[String:Any]]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupTableView()
        fetchUsers()
        // Do any additional setup after loading the view.
    }

    func fetchUsers(){
        LoginModel().fetchUsersFromDb { users, error in
            if let error = error {
                AlerUser().alertUser(viewController: self, title: "Error", message: error)
                return
            }
            
            self.chatUserArray = users
            self.usersTable.reloadData()
        }
    }
    
    func setupUI() {
        let backButtonWidth: CGFloat = 50
        let backButtonHeight: CGFloat = 50
        let backButtonX: CGFloat = 15
        let backButtonY: CGFloat = 40
        
        let backButton = UIButton(type: .custom)
        backButton.frame = CGRect(x: backButtonX, y: backButtonY, width: backButtonWidth, height: backButtonHeight)
        backButton.setImage(UIImage(systemName: "arrow.backward"), for: .normal)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backButton.tintColor = .black
        view.addSubview(backButton)
        
        let headerLabelX: CGFloat = backButton.frame.maxX
        let headerLabelY: CGFloat = 40
        let headerLabelWidth: CGFloat = view.bounds.width - backButton.frame.maxX - 15
        let headerLabelHeight: CGFloat = 30
        
        let headerLabel = UILabel(frame: CGRect(x: headerLabelX, y: headerLabelY, width: headerLabelWidth, height: headerLabelHeight))
        headerLabel.textAlignment = .center
        headerLabel.text = "Add Users"
        view.addSubview(headerLabel)
        
        let usersTableY: CGFloat = headerLabel.frame.maxY + 20
        let usersTableHeight: CGFloat = view.bounds.height - usersTableY
        usersTable = UITableView(frame: CGRect(x: 0, y: usersTableY, width: view.bounds.width, height: usersTableHeight))
        view.addSubview(usersTable)
    }


    func setupTableView(){
        usersTable.delegate = self
        usersTable.dataSource = self
        usersTable.backgroundColor = .systemGray6
        usersTable.register(UINib(nibName: "ListChatTableViewCell", bundle: .main), forCellReuseIdentifier: "listChatTableView")
        usersTable.rowHeight = UITableView.automaticDimension
    }
    
    @objc func backButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
}

extension AddUsersViewController:UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatUserArray?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "listChatTableView", for: indexPath) as? ListChatTableViewCell else {
            return UITableViewCell()
        }
        
        // timepass
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let currentTime = dateFormatter.string(from: Date())
        
        
        if let chatUserArray = chatUserArray, indexPath.row < chatUserArray.count {
            let user = chatUserArray[indexPath.row]
            
            let username = user["displayName"] as? String ?? ""
            let avtarURL = user["photoURL"] as? String ?? ""
            
            cell.setCellData(userImage: avtarURL, username: username, userRecentMeassage: "Placeholder", meassageTime: currentTime)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // MARK: Call API to add users UID
        if let chatUserArray = chatUserArray, indexPath.row < chatUserArray.count {
            let user = chatUserArray[indexPath.row]
            let userUID = user["uid"] as? String ?? ""
            let conversationID = MessageModel().generateConversationID(user1ID: authUser?.uid ?? "", user2ID: userUID)
            LoginModel().connectUsersInDB(conversationID: conversationID) { isSucceeded, error in
                if let error = error {
                    AlerUser().alertUser(viewController: self, title: "Error", message: error)
                }
                if isSucceeded {
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
}
