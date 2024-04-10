//
//  AddUsersViewController.swift
//  Chatbot
//
//  Created by Umang Kedan on 23/03/24.
//

import UIKit
import FirebaseAuth
import NVActivityIndicatorView

protocol AddUsersDelegate: AnyObject {
    func didSelectUser(_ username:String?, userAvtar:String?, userUID:String, conversationID:String?)
}

class AddUsersViewController: UIViewController {

    lazy var usersTable = UITableView()
    lazy var groupNameTextField = UITextField()
    lazy var groupImageView = UIImageView()
    
    var authUser:AuthenticatedUser?
    var chatUserArray:[[String:Any]]?
    var is_Group = false
    var selectedUsers: [String] = [] // to be used by group users
    
    weak var delegate: AddUsersDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchUsers()
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupUI()
        setupTableView()
        
        if is_Group {
            setupGroupPhotoPicker()
        }
    }

    func fetchUsers(){
        LoginModel().fetchUsersFromDb(currentUserUID: authUser?.uid ?? "") { users, error in
            if let error = error {
                AlerUser().alertUser(viewController: self, title: "Error", message: error)
                return
            }
            
            self.chatUserArray = users
            self.usersTable.reloadData()
        }
    }
    
    func setupUI() {
        let headerHeight: CGFloat = 90
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: headerHeight))
        
        let backButton = UIButton(type: .custom)
        backButton.frame = CGRect(x: 24, y: 60, width: 24, height: 24)
        backButton.setImage(UIImage(systemName: "arrow.backward"), for: .normal)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backButton.tintColor = .black
        headerView.addSubview(backButton)
        
        let headerLabel = UILabel(frame: CGRect(x: backButton.frame.origin.x + 30, y: backButton.frame.origin.y, width: 300, height: 30))
        headerLabel.textAlignment = .center
        headerLabel.font = UIFont(name: "Rubik-SemiBold", size: 18)
        headerLabel.textColor = UIColorHex().hexStringToUIColor(hex: "#191919")
        headerView.addSubview(headerLabel)
        
        var usersTableY: CGFloat?
        let usersTableHeight: CGFloat = view.bounds.height - (usersTableY ?? 0)
        
        if is_Group {
            headerLabel.text = "Add Group"
            // Add a "Done" button
            let doneButton = UIButton(type: .system)
            doneButton.frame = CGRect(x: view.frame.width - 46, y: headerLabel.frame.origin.y, width: 24, height: headerLabel.frame.height)
            doneButton.setImage(UIImage(systemName: "checkmark.circle"), for: .normal)
            doneButton.tintColor = .black
            doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
            headerView.addSubview(doneButton)
            
            // Group Image
            groupImageView.contentMode = .scaleAspectFit
            groupImageView.clipsToBounds = true
            groupImageView.frame = CGRect(x: (view.frame.width - 120) / 2, y: headerView.frame.maxY + 40, width: 120, height: 120)
            groupImageView.layer.cornerRadius = 60
            groupImageView.image = UIImage(systemName: "person.3.sequence.fill")
            groupImageView.tintColor = .black
            view.addSubview(groupImageView)
            
            // Add a text field for group name
            let groupNameTextFieldY: CGFloat = groupImageView.frame.maxY + 20
            let groupNameTextFieldHeight: CGFloat = 40
            groupNameTextField = UITextField(frame: CGRect(x: 15, y: groupNameTextFieldY, width: view.bounds.width - 30, height: groupNameTextFieldHeight))
            groupNameTextField.placeholder = "Enter Group Name"
            groupNameTextField.borderStyle = .roundedRect
            groupNameTextField.backgroundColor = .white
            view.addSubview(groupNameTextField)
            
            usersTableY = groupNameTextField.frame.maxY + 20
        } else {
            headerLabel.text = "Add Users"
            usersTableY = headerLabel.frame.maxY + 20
        }
        
        view.addSubview(headerView)
        usersTable = UITableView(frame: CGRect(x: 0, y: usersTableY ?? 0, width: view.bounds.width, height: usersTableHeight))
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
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func doneButtonTapped() {
        let conversationID = GroupModel().generateGroupConversationID(authUserUID: authUser?.uid ?? "")
        
        // Call API to add users to the group
        GroupModel().connectUsersInGroupChatInDB(authUserUID: authUser?.uid ?? "", conversationID: conversationID, groupName: groupNameTextField.text ?? "", groupAvtar: groupImageView.image, userIDs: selectedUsers) { isSucceeded, error in
            if let error = error {
                AlerUser().alertUser(viewController: self, title: "Error", message: error)
            }
            if isSucceeded {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func setupGroupPhotoPicker(){
        // Add tap gesture recognizer to profile photo image view
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(groupPhotoTapped))
        groupImageView.isUserInteractionEnabled = true
        groupImageView.addGestureRecognizer(tapGesture)
    }
    
    @objc func groupPhotoTapped() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        present(imagePickerController, animated: true, completion: nil)
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
            
            cell.setCellData(userImage: avtarURL, username: username, userRecentMeassage: nil, meassageTime: nil, messageReadState: false)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let chatUserArray = chatUserArray, indexPath.row < chatUserArray.count else {
            return
        }
        
        let user = chatUserArray[indexPath.row]
        let userUID = user["uid"] as? String ?? ""
        let username = user["displayName"] as? String ?? ""
        let avtarURL = user["photoURL"] as? String ?? ""
        
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
            LoginModel().connectUsers(authUserUID: authUser?.uid ?? "", otherUserUID: userUID, conversationID: conversationID) { isSucceeded, error in
                if let error = error {
                    AlerUser().alertUser(viewController: self, title: "Error", message: error)
                }
                if isSucceeded {
                    if let delegate = self.delegate {
                        delegate.didSelectUser(username, userAvtar: avtarURL, userUID: userUID, conversationID: conversationID)
                    }
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
}

extension AddUsersViewController:UITextFieldDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            groupImageView.image = selectedImage
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
