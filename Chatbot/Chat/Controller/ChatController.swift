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
import NVActivityIndicatorView

class ChatController: UIViewController {
    
    private var messages = [Message]()
    
    @IBOutlet var heightConstraintTextView: NSLayoutConstraint!
    @IBOutlet var messageTableView: UITableView!
    @IBOutlet var sendButton: UIButton!
    @IBOutlet var inputTextView: GrowingTextView!
    
    var conversationID: String?
    var senderUserName: String?
    var senderPhotoURL: String?
    var senderUID: String?
    var authUser:AuthenticatedUser?
    
    var photoUrl:URL?
    
    // MessageActions
    var editMessageAction:Bool = false
    var currentMessage:Message?
    
    // Audio Record
    var audioRecorderView: AudioRecorderView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setInputTF()
        observeMessages()
        sendButton.layer.cornerRadius = sendButton.frame.height / 2
        setupRecordView()
        setupAudioRecord()
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
        messageTableView.register(UINib(nibName: "AudioMessageTableViewCell", bundle: nil), forCellReuseIdentifier: "audioMessageTableViewCell")
        messageTableView.register(UINib(nibName: "MessageTableViewCell", bundle: nil), forCellReuseIdentifier: "messageTableViewCell")
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        messageTableView.addGestureRecognizer(longPressGesture)
    }
    
    @objc func backButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func observeMessages() {
        ChatModel().observeMessages(conversationID: conversationID ?? "") { message,error  in
            if let error = error {
                //AlerUser().alertUser(viewController: self, title: "Error", message: "\(error)")
                return
            }
            // empty message array every time
            self.messages.removeAll()
            
            // Append the new message to the messages array
            self.messages.append(contentsOf: message!)
            
            // Reload the messages collection view to display the new message
            self.messageTableView.reloadData()
            
            ChatModel().markMessagesRead(conversationId: self.conversationID ?? "", messages: self.messages, index: 0) { isSucceeded, error in
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
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
        
        inputTextView.frame.size = inputTextView.sizeThatFits(CGSize(width: inputTextView.frame.width, height: 56))
        
        if editMessageAction == false {
            
            let newMessage = Message(sender: Sender(senderId: authUser?.uid ?? "", displayName: authUser?.displayName ?? ""),
                                     messageId: "\(authUser?.uid ?? "")", // Set an appropriate message ID
                                     sentDate: Date(),
                                     kind: .text(messageText), state: false)
            
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
        } else {
            ChatModel().editChildNodeFromConversation(conversationId: conversationID ?? "", message: currentMessage!, updatedMessageText: messageText) { isSucceeded, error in
                if let error = error {
                    AlerUser().alertUser(viewController: self, title: "Error", message: error)
                }
                
                if isSucceeded {
                    self.editMessageAction = false
                    self.sendButton.setImage(UIImage(systemName: "bubble.fill"), for: .normal)
                    self.observeMessages()
                }
            }
        }
    }
    
    @objc func onTouch(){
        let userDetailController = UserDetailController()
        userDetailController.userUID = senderUID
        navigationController?.pushViewController(userDetailController, animated: true)
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
        
        let copyAction = UIAlertAction(title: "Copy", style: .default) { (action) in
            UIPasteboard.general.string = selectedMessage.kind.decode
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        var messageActions:[UIAlertAction] = [copyAction, cancelAction]
        
        if authUser?.uid == selectedMessage.sender.senderId {
            let editAction = UIAlertAction(title: "Edit Message", style: .default) { _ in
                self.updateMessage(at: indexPath)
            }
            
            let deleteAction = UIAlertAction(title: "Delete Message", style: .destructive) { _ in
                self.deleteMessage(at: indexPath)
            }
            
            messageActions.append(editAction)
            messageActions.append(deleteAction)
        }
        
        AlerUser().alertUser(viewController: self, title: selectedMessage.kind.decode, message: "Message Options", actions: messageActions)
    }
    
    func updateMessage(at indexPath: IndexPath) {
        editMessageAction = true
        currentMessage = messages[indexPath.row]
        inputTextView.placeholder = messages[indexPath.row].kind.decode
        sendButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
    }

    func deleteMessage(at indexPath: IndexPath) {
        // Update database
        ChatModel().removeChildNodeFromConversation(conversationId: conversationID ?? "", messageId: messages[indexPath.row].messageId) { isSucceeded, error in
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
    
    func setupRecordView(){
        audioRecorderView = AudioRecorderView(frame: CGRect(x: 24, y: messageTableView.frame.maxY + 19, width: 270, height: 60))
        audioRecorderView.view = self
        audioRecorderView.conversationID = conversationID
        audioRecorderView.sender = authUser
        audioRecorderView.layer.cornerRadius = 15
        audioRecorderView.layer.masksToBounds = true
        audioRecorderView.isHidden = true
        audioRecorderView.backgroundColor = .systemGray6
        view.addSubview(audioRecorderView)
    }
    
    func setupAudioRecord(){
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleSendButtonLongPress(_:)))
        sendButton.addGestureRecognizer(longPressGesture)
    }
    
    @objc func handleSendButtonLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            // Hide input text view and show record view
            inputTextView.isHidden = true
            audioRecorderView.isHidden = false
            audioRecorderView.startRecording()

        case .changed:
            guard gestureRecognizer.view != nil else { return }
            let location = gestureRecognizer.location(in: gestureRecognizer.view)
            let percentage = Float(location.x / gestureRecognizer.view!.bounds.width)

        case .ended, .cancelled, .failed:
            // Show input text view and hide record view
            audioRecorderView.stopRecording()
            sendButton.isEnabled = false
            audioRecorderView.result = { success, error in
                if success {
                    self.inputTextView.isHidden = false
                    self.audioRecorderView.isHidden = true
                    self.sendButton.isEnabled = true
                }
                if let error = error {
                    AlerUser().alertUser(viewController: self, title: "Error", message: error.description)
                }
            }

        default:
            break
        }
    }
}

extension ChatController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        
        guard let authUser = authUser else{
            return UITableViewCell()
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        
        if case .audio(let url) = message.kind {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "audioMessageTableViewCell", for: indexPath) as? AudioMessageTableViewCell else {
                return UITableViewCell()
            }
            
            if message.sender.senderId == authUser.uid {
                cell.setCellData(audioURL: url, messageStatus: "\(dateFormatter.string(from: message.sentDate))", senderAvatarURL: authUser.photoURL, isCurrentUser: true, messageReadStatus: message.state, view: self)
            } else {
                cell.setCellData(audioURL: url, messageStatus: "\(dateFormatter.string(from: message.sentDate))", senderAvatarURL: senderPhotoURL, isCurrentUser: false, view: self)
            }
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "messageTableViewCell", for: indexPath) as? MessageTableViewCell else {
                return UITableViewCell()
            }
            
            if message.sender.senderId == authUser.uid {
                cell.setCellData(message: message.kind.decode, messageStatus: "\(dateFormatter.string(from: message.sentDate))", senderAvtar: authUser.photoURL, isCurrentUser: true, messageReadStatus: message.state)
            } else {
                cell.setCellData(message: message.kind.decode, messageStatus: "\(dateFormatter.string(from: message.sentDate))", senderAvtar: senderPhotoURL, isCurrentUser: false)
            }
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        false
    }
}
 
extension ChatController : GrowingTextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        let textIsEmpty = textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        if textIsEmpty {
            sendButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        } else {
            sendButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        }
    }
}
