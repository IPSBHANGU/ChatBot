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
import GrowingTextView

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
    @IBOutlet weak var inputTextView: GrowingTextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setInputTF()
        observeMessages()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupHeaderView()
        setupTableView()
    }
    
    func setInputTF(){
        inputTextView.isScrollEnabled = true
        inputTextView.delegate = self
        inputTextView.becomeFirstResponder()
        inputTextView.font = UIFont(name: "Rubik-Regular.ttf", size: 25)
        inputTextView.backgroundColor = UIColorHex().hexStringToUIColor(hex: "#F4F4F4")
        messageTableView.isUserInteractionEnabled = true
        inputTextView.layer.cornerRadius = 15
        inputTextView.layer.masksToBounds = true
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
            
            GroupModel().markMessagesRead(conversationId: self.conversationID ?? "", messages: self.messages, index: 0) { isSucceeded, error in
                if let error = error {
                    AlerUser().alertUser(viewController: self, title: "Error", message: "Error while marking message as read error \(error.description)")
                }

                if isSucceeded {
                    self.messageTableView.reloadData()
                }
            }
            
            // Scroll to the last message
            DispatchQueue.main.async {
                let indexPath = IndexPath(row: self.messages.count-1, section: 0)
                self.messageTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
        }
    }
    
    
    @IBAction func sendButtonAction(_ sender: Any) {
        guard let messageText = inputTextView.text, !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        self.inputTextView.text = ""
        
        inputTextView.frame.size = inputTextView.sizeThatFits(CGSize(width: inputTextView.frame.width, height: 56))
        
        let newMessage = GroupMessage(sender: Sender(senderId: authUser?.uid ?? "", displayName: authUser?.displayName ?? ""),
                                 messageId: "\(authUser?.uid ?? "")", // Set an appropriate message ID
                                 sentDate: Date(),
                                      kind: .text(messageText), senderAvtar: authUser?.photoURL ?? "", state: false)

        // Append the new message to the messages array
        messages.append(newMessage)

        // Reload the table view to display the new message
        messageTableView.reloadData()


        GroupModel().sendGroupMessage(conversationID: conversationID ?? "", sender: authUser, message: messageText) { error in
            if let error = error {
                AlerUser().alertUser(viewController: self, title: "Error", message: error)
            } else {
                // Clear the input text after sending message
                self.inputTextView.text = ""
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
        if message.sender.senderId == authUser.uid {
            cell.setCellData(message: message.kind.decode, messageStatus: "\(dateFormatter.string(from: message.sentDate))", senderAvtar: authUser.photoURL, isCurrentUser: true, messageReadStatus: message.state)
        } else {
            cell.setCellData(message: message.kind.decode, messageStatus: "\(dateFormatter.string(from: message.sentDate))", senderAvtar: photoURL, isCurrentUser: false)
        }
        return cell
    }
}

extension GroupChatController : GrowingTextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        sendButton.isEnabled = true
       }
}
