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
    lazy var groupNameTextField = UITextField()
    
    var authUser:User?
    var chatUserArray:[[String:Any]]?
    var is_Group = false
    var selectedUsers: [String] = [] // to be used by group users
    
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
        
        // Add a "Done" button
        let doneButtonWidth: CGFloat = 80
        let doneButtonHeight: CGFloat = 40
        let doneButtonX: CGFloat = view.bounds.width - doneButtonWidth - 15
        let doneButtonY: CGFloat = headerLabel.frame.minY
        let doneButton = UIButton(type: .system)
        doneButton.frame = CGRect(x: doneButtonX, y: doneButtonY, width: doneButtonWidth, height: doneButtonHeight)
        doneButton.setTitle("Done", for: .normal)
        doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        view.addSubview(doneButton)
        
        // Add a text field for group name
        let groupNameTextFieldY: CGFloat = headerLabel.frame.maxY + 20
        let groupNameTextFieldHeight: CGFloat = 40
        groupNameTextField = UITextField(frame: CGRect(x: 15, y: groupNameTextFieldY, width: view.bounds.width - 30, height: groupNameTextFieldHeight))
        groupNameTextField.placeholder = "Enter Group Name"
        groupNameTextField.borderStyle = .roundedRect
        groupNameTextField.backgroundColor = .white
        view.addSubview(groupNameTextField)
        
        let usersTableY: CGFloat = groupNameTextField.frame.maxY + 20
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
    
    @objc func doneButtonTapped() {
        
        let conversationID = GroupModel().generateGroupConversationID(userIDs: selectedUsers)
        
        // Call API to add users to the group
        GroupModel().connectUsersInGroupChatInDB(conversationID: conversationID, groupName: groupNameTextField.text ?? "") { isSucceeded, error in
            if let error = error {
                AlerUser().alertUser(viewController: self, title: "Error", message: error)
            }
            if isSucceeded {
                self.dismiss(animated: true, completion: nil)
            }
        }
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
        
        if let chatUserArray = chatUserArray, indexPath.row < chatUserArray.count {
            let user = chatUserArray[indexPath.row]
            
            let username = user["displayName"] as? String ?? ""
            let avtarURL = user["photoURL"] as? String ?? ""
            
            cell.setCellData(userImage: avtarURL, username: username, userRecentMeassage: nil, meassageTime: nil)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let chatUserArray = chatUserArray, indexPath.row < chatUserArray.count else {
            return
        }
        
        let user = chatUserArray[indexPath.row]
        let userUID = user["uid"] as? String ?? ""
        
        if is_Group {
            // Group chat logic
            if let cell = tableView.cellForRow(at: indexPath) {
                if selectedUsers.contains(userUID) {
                    // Deselect the user
                    cell.accessoryType = .none
                    if let index = selectedUsers.firstIndex(of: userUID) {
                        selectedUsers.remove(at: index)
                    }
                } else {
                    // Select the user
                    cell.accessoryType = .checkmark
                    selectedUsers.append(userUID)
                }
            }
        } else {
            // Single chat logic
            let conversationID = ChatModel().generateConversationID(user1ID: authUser?.uid ?? "", user2ID: userUID)
            
            // Call API to connect users in DB
            LoginModel().connectUsersInDB(authUserUID: authUser?.uid ?? "", otherUserUID: userUID, conversationID: conversationID) { isSucceeded, error in
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
