//
//  ChatController.swift
//  Chatbot
//
//  Created by Umang Kedan on 20/03/24.
//

import UIKit
import FirebaseAuth
import Kingfisher
import FirebaseDatabaseInternal
import GrowingTextView

class ChatController: UIViewController {
    
    private var messages = [Message]()
    
    @IBOutlet var heightConstraintTextView: NSLayoutConstraint!
    @IBOutlet var messageTableView: UITableView!
    @IBOutlet var sendButton: UIButton!
    @IBOutlet var inputTextView: GrowingTextView!
    
    var selfSender: SenderType?
    var conversationID: String?
    var senderUserName: String?
    var senderPhotoURL: String?
    var senderUID: String?
    var authUser:AuthenticatedUser?
    
    var photoUrl:URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setInputTF()
        observeMessages()
        sendButton.isEnabled = false
        sendButton.layer.cornerRadius = sendButton.frame.height / 2
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupHeaderView()
        setupTableView()
    }
    
    func setInputTF(){
        inputTextView.isScrollEnabled = false
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
        backButton.frame = CGRect(x: 24, y: 60, width: 24, height: 24)
        backButton.setImage(UIImage(systemName: "arrow.backward"), for: .normal)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backButton.tintColor = .black
        headerView.addSubview(backButton)
        
        let headerLabel = UILabel(frame: CGRect(x: backButton.frame.origin.x + 30, y: backButton.frame.origin.y, width: 300, height: 30))
        headerLabel.textAlignment = .center
        headerLabel.text = "\(senderUserName ?? "")"
        headerLabel.font = UIFont(name: "Rubik-SemiBold", size: 18)
        headerLabel.textColor = UIColorHex().hexStringToUIColor(hex: "#191919")
        headerLabel.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTouch))
        headerLabel.addGestureRecognizer(tapGesture)
        headerView.addSubview(headerLabel)
        
        view.addSubview(headerView)
        
        messageTableView.frame = CGRect(x: 0, y: headerView.frame.maxY, width: view.frame.width, height: view.frame.height - 200 )
        view.addSubview(messageTableView)
    }

    func setupTableView(){
        messageTableView.delegate = self
        messageTableView.dataSource = self
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
        guard let messageText = inputTextView.text, !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        self.inputTextView.text = ""
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
        
        inputTextView.frame.size = inputTextView.sizeThatFits(CGSize(width: inputTextView.frame.width, height: 56))
        
        let newMessage = Message(sender: Sender(senderId: authUser?.uid ?? "", displayName: authUser?.displayName ?? ""),
                                 messageId: "\(authUser?.uid ?? "")", // Set an appropriate message ID
                                 sentDate: Date(),
                                 kind: .text(messageText))
        
        // Append the new message to the messages array
        messages.append(newMessage)
        
        // Reload the table view to display the new message
        messageTableView.reloadData()
        
        ChatModel().sendMessage(conversationID: conversationID ?? "", sender: authUser, message: messageText.trimmingCharacters(in: .whitespaces)) { error in
            if let error = error {
                AlerUser().alertUser(viewController: self, title: "Error", message: error)
            } else {
                // Clear the input text after sending message
                self.inputTextView.text = ""
            }
        }
    }
    
    @objc func onTouch(){
        let userDetailController = UserDetailController()
        userDetailController.userUID = senderUID
        navigationController?.pushViewController(userDetailController, animated: true)
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
                cell.setCellData(message: text, messageStatus: "\(dateFormatter.string(from: message.sentDate))", senderAvtar: authUser.photoURL, isCurrentUser: true)
            } else {
                cell.setCellData(message: text, messageStatus: "\(dateFormatter.string(from: message.sentDate))", senderAvtar: senderPhotoURL, isCurrentUser: false)
            }
        }
        return cell
    }
}
 
extension ChatController : GrowingTextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        sendButton.isEnabled = true
          
       }
}
