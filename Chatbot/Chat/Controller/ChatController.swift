//
//  ChatController.swift
//  Chatbot
//
//  Created by Inderpreet Singh on 20/03/24.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import IQKeyboardManager
import FirebaseAuth
import Kingfisher
import FirebaseDatabaseInternal


class ChatController: MessagesViewController {
    
    private var messages = [Message]()
    
    var selfSender: SenderType?
    var name: String?
    var password: String?
    var email: String?
    
    var conversationID: String?
    var senderUserName: String?
    var senderPhotoURL: String?
    var senderUID: String?
    var authUser:User?
    
    var photoUrl:URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messageInputBar.delegate = self
        
        observeMessages()
        messagesSend()
        setupHeaderView()
        setupMessageViewFeatures()
    }
    
    func setupMessageViewFeatures(){
        self.showMessageTimestampOnSwipeLeft = true
    }
    
    func messagesSend() {
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
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
        headerLabel.text = senderUserName ?? ""
        headerView.addSubview(headerLabel)
        
        view.addSubview(headerView)
        
        let messagesCollectionViewY = headerView.frame.maxY
        messagesCollectionView.frame = CGRect(x: 0, y: messagesCollectionViewY, width: view.frame.width, height: view.frame.height - messagesCollectionViewY)
    }

    
    @objc func backButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func observeMessages() {
        MessageModel().observeMessages(conversationID: conversationID ?? "", currentUserID: self.authUser?.uid ?? "", otherUserID: self.senderUID ?? "") { message in
            
            // empty message array every time
            self.messages.removeAll()
            
            // Append the new message to the messages array
            self.messages.append(contentsOf: message)
            
            // Reload the messages collection view to display the new message
            self.messagesCollectionView.reloadData()
            
            // Scroll to the last message
            DispatchQueue.main.async {
                self.messagesCollectionView.scrollToLastItem(animated: true)
            }
        }
    }
}

extension ChatController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> SenderType {
        return selfSender ?? Sender(senderId: authUser?.uid ?? "", displayName: authUser?.displayName ?? "")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        if message.sender.senderId == self.authUser?.uid {
            avatarView.kf.setImage(with: authUser?.photoURL)
        } else if message.sender.displayName == self.senderUserName {
            avatarView.kf.setImage(with: URL(string: self.senderPhotoURL ?? ""))
        } else {
            avatarView.image = UIImage(systemName: "person")
        }
    }
    
    func headerViewSize(for section: Int, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        CGSize(width: 0, height: 30)
    }
    
    func messageTimestampLabelAttributedText(for message: any MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let dateString = formatter.string(from: message.sentDate)
        return NSAttributedString(string: dateString, attributes: [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.darkGray
        ])
    }
}

extension ChatController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        // Ensure there's text entered by the user
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let newMessage = [
            "senderId": authUser?.uid ?? "",
            "displayName": authUser?.displayName ?? "",
            "text": text,
            "sentDate": Date().timeIntervalSince1970
        ] as [String : Any]

        MessageModel().sendMessage(conversationID: conversationID ?? "", senderID: authUser?.uid ?? "", senderDisplayName: authUser?.displayName ?? "", message: text) { error in
            if let error = error {
                AlerUser().alertUser(viewController: self, title: "Error", message: error)
            }
        }
        
        // Clear the input text
        inputBar.inputTextView.text = ""
    }
}
