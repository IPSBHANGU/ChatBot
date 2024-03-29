//
//  ChatController.swift
//  Chatbot
//
//  Created by Umang Kedan on 20/03/24.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import IQKeyboardManager
import FirebaseAuth
import Kingfisher
import FirebaseDatabaseInternal

class ChatController: UIViewController {
    
    private var messages = [Message]()
    
    @IBOutlet var sendButton: UIButton!
    @IBOutlet var inputTextField: UITextField!
   
    
    var selfSender: SenderType?
    var conversationID: String?
    var senderUserName: String?
    var senderPhotoURL: String?
    var senderUID: String?
    var authUser:User?
    
    var photoUrl:URL?
    
    lazy var messageTableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        inputTextField.delegate = self
        inputTextField.becomeFirstResponder()
        inputTextField.font = UIFont(name: "Rubik-Regular.ttf", size: 15)
        inputTextField.placeholder = "Send a message..."
        inputTextField.backgroundColor = UIColorHex().hexStringToUIColor(hex: "#F4F4F4")
        inputTextField.layer.cornerRadius = 16
        observeMessages()
        setupHeaderView()
        setupTableView()
        sendButton.layer.cornerRadius = sendButton.frame.height / 2
        
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
        headerLabel.text = "Messages"
        headerLabel.font = UIFont(name: "Rubik SemiBold", size: 18)
        headerLabel.textColor = UIColorHex().hexStringToUIColor(hex: "#191919")
        headerView.addSubview(headerLabel)
        
        view.addSubview(headerView)
        
        messageTableView.frame = CGRect(x: 0, y: headerView.frame.maxY, width: view.frame.width, height: view.frame.height - 200 )
        view.addSubview(messageTableView)
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
    }
    
    @objc func backButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func observeMessages() {
        ChatModel().observeMessages(conversationID: conversationID ?? "", currentUserID: self.authUser?.uid ?? "", otherUserID: self.senderUID ?? "") { message in
            
            // empty message array every time
            self.messages.removeAll()
            
            // Append the new message to the messages array
            self.messages.append(contentsOf: message)
            
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

               let newMessage = Message(sender: Sender(senderId: authUser?.uid ?? "", displayName: authUser?.displayName ?? ""),
                                        messageId: "\(authUser?.uid ?? "")", // Set an appropriate message ID
                                        sentDate: Date(),
                                        kind: .text(messageText))

               // Append the new message to the messages array
               messages.append(newMessage)

               // Reload the table view to display the new message
               messageTableView.reloadData()

               ChatModel().sendMessage(conversationID: conversationID ?? "", senderID: authUser?.uid ?? "", senderDisplayName: authUser?.displayName ?? "", message: messageText) { error in
                   if let error = error {
                       AlerUser().alertUser(viewController: self, title: "Error", message: error)
                   } else {
                       // Clear the input text after sending message
                       self.inputTextField.text = ""
                   }
               }
           }
}

extension ChatController: UITableViewDelegate, UITableViewDataSource {
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

                if case let .text(text) = message.kind {
                    if message.sender.senderId == authUser.uid {
                        cell.setCellData(message: text, messageStatus: "\(dateFormatter.string(from: message.sentDate))", senderAvtar: authUser.photoURL?.absoluteString, isCurrentUser: true)
                    } else {
                        cell.setCellData(message: text, messageStatus: "\(dateFormatter.string(from: message.sentDate))", senderAvtar: senderPhotoURL, isCurrentUser: false)
                    }
                }
                return cell
        
    }
    
}
 
extension ChatController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}
