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

struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
}

struct Sender: SenderType {
    var photoURL: String
    var senderId: String
    var displayName: String
}

class ChatController: MessagesViewController {
    
    private var messages = [Message]()
    
    var selfSender: SenderType?
    var name: String?
    var password: String?
    var email: String?
    
    var displayUserName: String?
    var authUser:User?
    
    var photoUrl:URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messageInputBar.delegate = self
        
        photoUrl = authUser?.photoURL
        self.selfSender = Sender(photoURL: photoUrl?.absoluteString ?? "", senderId: "1", displayName: displayUserName ?? "")
        messagesSend()
        setupHeaderView()
    }
    
    func messagesSend() {
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
    }
    
    func setupHeaderView() {
        let headerHeight: CGFloat = 50
        let headerView = UIView(frame: CGRect(x: 0, y: 40, width: view.frame.width, height: headerHeight))
        headerView.backgroundColor = .clear
        
        let backButton = UIButton(type: .custom)
        backButton.frame = CGRect(x: 10, y: 20, width: 50, height: 30)
        backButton.setImage(UIImage(systemName: "arrow.backward"), for: .normal)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backButton.tintColor = .black
        headerView.addSubview(backButton)
        
        let headerLabel = UILabel(frame: CGRect(x: 60, y: 20, width: view.frame.width - 120, height: 30)) // Adjusted the x position
        headerLabel.textAlignment = .center
        headerLabel.text = displayUserName ?? ""
        headerView.addSubview(headerLabel)
        
        view.addSubview(headerView)
        
        let messagesCollectionViewY = headerView.frame.maxY // Start messagesCollectionView below headerView
        messagesCollectionView.frame = CGRect(x: 0, y: messagesCollectionViewY, width: view.frame.width, height: view.frame.height - messagesCollectionViewY)
    }

    
    @objc func backButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
}

extension ChatController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> SenderType {
        return selfSender ?? Sender(photoURL: photoUrl?.absoluteString ?? "", senderId: "1", displayName: displayUserName ?? "")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        // MARK: TO-DO handle users
        avatarView.kf.setImage(with: photoUrl)
    }
    
    func headerViewSize(for section: Int, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        CGSize(width: 0, height: 30)
    }
}

extension ChatController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        // Ensure there's text entered by the user
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let newMessage = Message(sender: currentSender(),
                                 messageId: UUID().uuidString,
                                 sentDate: Date(),
                                 kind: .text(text))
        
        // Append the new message to the messages array
        messages.append(newMessage)
        
        // Reload the messages collection view to display the new message
        messagesCollectionView.reloadData()
        
        // Scroll to the last message
        DispatchQueue.main.async {
            self.messagesCollectionView.scrollToLastItem(animated: true)
        }
        
        // Clear the input text
        inputBar.inputTextView.text = ""
    }
}
