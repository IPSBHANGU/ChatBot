//
//  GroupChatController.swift
//  Chatbot
//
//  Created by Umang Kedan on 25/03/24.
//

import UIKit
import FirebaseAuth
import Kingfisher
import FirebaseDatabaseInternal

class GroupChatController: UIViewController {
    
    private var messages = [GroupMessage]()
    
    var selfSender: SenderType?
    var authUser:AuthenticatedUser?
    var conversationID: String?
    var groupName: String?
    
    // group Users
    var groupAdmin:String?
    var groupAvtar:String?
    var groupMembers:[String]?
    
    lazy var messageTableView = UITableView()
    
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var inputTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        inputTextField.delegate = self
        inputTextField.becomeFirstResponder()
        
        observeMessages()
        setupHeaderView()
        setupTableView()
    }
    
    func setupHeaderView() {
        let headerHeight: CGFloat = 90
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: headerHeight))
        headerView.backgroundColor = .white
        
        let backButton = UIButton(type: .custom)
        backButton.frame = CGRect(x: 10, y: 60, width: 50, height: 30)
        backButton.setImage(UIImage(systemName: "arrow.backward"), for: .normal)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backButton.tintColor = .black
        headerView.addSubview(backButton)
        
        let headerLabel = UILabel(frame: CGRect(x: 60, y: 60, width: view.frame.width - 120, height: 30))
        headerLabel.textAlignment = .center
        headerLabel.text = groupName ?? ""
        headerView.addSubview(headerLabel)

        view.addSubview(headerView)
        
        headerLabel.isUserInteractionEnabled = true
    
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTouch))
        headerLabel.addGestureRecognizer(tapGesture)
        
        messageTableView.frame = CGRect(x: 0, y: headerView.frame.maxY, width: view.frame.width, height: view.frame.height - 190 )
        view.addSubview(messageTableView)
    }

    @objc func onTouch(){
        let groupDetailController = GroupDetailsController()
        groupDetailController.admin = groupAdmin
        groupDetailController.groupAvtar = groupAvtar
        groupDetailController.members = groupMembers!
        groupDetailController.groupName = groupName 
        navigationController?.pushViewController(groupDetailController, animated: true)
    }


    func setupTableView(){
        messageTableView.separatorStyle = .none
        messageTableView.delegate = self
        messageTableView.dataSource = self
        messageTableView.backgroundColor = .white
        messageTableView.tintColor = .white
        messageTableView.rowHeight = UITableView.automaticDimension
        messageTableView.estimatedRowHeight = 100
        messageTableView.register(UINib(nibName: "MessageTableViewCell", bundle: .main), forCellReuseIdentifier: "messageTableViewCell")
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        messageTableView.addGestureRecognizer(longPressGesture)
    }
    
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: messageTableView)
            if let indexPath = messageTableView.indexPathForRow(at: touchPoint) {
                // A cell was long-pressed, perform your action here
                handleCellLongPress(at: indexPath)
            }
        }
    }

    func handleCellLongPress(at indexPath: IndexPath) {
        let selectedMessage = messages[indexPath.row]

        var messageString:String = ""
        let messageText = selectedMessage.kind
        switch messageText {
        case .text(let text):
            messageString = text
        }

        let copyAction = UIAlertAction(title: "Copy", style: .default) { (action) in
            UIPasteboard.general.string = messageString
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        var messageActions:[UIAlertAction] = [copyAction, cancelAction]

        if authUser?.uid == selectedMessage.sender.senderId {
            let deleteAction = UIAlertAction(title: "Delete Message", style: .destructive) { _ in
                self.deleteMessage(at: indexPath)
            }

            messageActions.append(deleteAction)
        }

        AlerUser().alertUser(viewController: self, title: messageString, message: "Message Options", actions: messageActions)
    }

    func deleteMessage(at indexPath: IndexPath) {
        // Update database
        GroupModel().removeChildNodeFromConversation(conversationId: conversationID ?? "", messageId: messages[indexPath.row].messageId) { isSucceeded, error in
            if let error = error {
                AlerUser().alertUser(viewController: self, title: "Error", message: error)
            }
            if isSucceeded {
                // Remove the message from messages array
                self.messages.remove(at: indexPath.row)

                // Update the table view to reflect the changes
                self.messageTableView.deleteRows(at: [indexPath], with: .automatic)
            }
        }
    }
    
    @objc func backButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func observeMessages() {
        GroupModel().observeGroupMessages(conversationID: conversationID ?? "") { message,error  in
            
            if let error = error {
                print(error)
            }
            // empty message array every time
            self.messages.removeAll()
            
            // Append the new message to the messages array
            self.messages.append(contentsOf: message!)
            
            // Reload the messages collection view to display the new message
            self.messageTableView.reloadData()
            
            // Scroll to the last message
            DispatchQueue.main.async {
                let indexPath = IndexPath(row: self.messages.count-1, section: 0)
                self.messageTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
        }
    }
    
    
    @IBAction func sendButtonAction(_ sender: Any) {
        guard let messageText = inputTextField.text, !messageText.isEmpty else {
            return
        }
        
        let newMessage = GroupMessage(sender: Sender(senderId: authUser?.uid ?? "", displayName: authUser?.displayName ?? ""),
                                 messageId: "\(authUser?.uid ?? "")", // Set an appropriate message ID
                                 sentDate: Date(),
                                      kind: .text(messageText), senderAvtar: authUser?.photoURL ?? "")

        // Append the new message to the messages array
        messages.append(newMessage)

        // Reload the table view to display the new message
        messageTableView.reloadData()


        GroupModel().sendGroupMessage(conversationID: conversationID ?? "", sender: authUser, message: messageText) { error in
            if let error = error {
                AlerUser().alertUser(viewController: self, title: "Error", message: error)
            } else {
                // Clear the input text after sending message
                self.inputTextField.text = ""
            }
        }
    }
}

extension GroupChatController:UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "messageTableViewCell", for: indexPath) as? MessageTableViewCell else {
            return UITableViewCell()
        }

        guard let authUser = authUser else{
            return UITableViewCell()
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"

        let photoURL = message.senderAvtar
        if case let .text(text) = message.kind {
            if message.sender.senderId == authUser.uid {
                cell.setCellData(message: text, messageStatus: "\(dateFormatter.string(from: message.sentDate))", senderAvtar: authUser.photoURL, isCurrentUser: true)
            } else {
                cell.setCellData(message: text, messageStatus: "\(dateFormatter.string(from: message.sentDate))", senderAvtar: photoURL, isCurrentUser: false)
            }
        }
        return cell
    }
}

extension GroupChatController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}
