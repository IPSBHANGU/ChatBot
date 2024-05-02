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
    @IBOutlet weak var messageTableViewBottomSpace: NSLayoutConstraint!
    @IBOutlet weak var sendButton: UIButton!
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
    var initialTouchPoint: CGPoint = CGPoint.zero
    var lockedAudioRecorderSendButton = UIButton(type: .system)
    var lockedAudioRecorderDeleteButton = UIButton(type: .system)
    
    // Media Share
    var attachMedia = UIButton(type: .system)
    var imageMessageView = ImageMessageHandler()
    var expandedImageView = ImageMessageHandler() // this will be shown when message cell is tapped
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setInputTF()
        observeMessages()
        sendButton.layer.cornerRadius = sendButton.frame.height / 2
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupHeaderView()
        setupTableView()
        setupRecordView()
        setupAudioRecord()
        setupImageMessage()
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
        messageTableView.register(UINib(nibName: "ImageViewTableViewCell", bundle: nil), forCellReuseIdentifier: "imageViewTableViewCell")
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
    
    private func commonSendButtonAction(){
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
    
    @IBAction func sendButtonAction(_ sender: Any) {
        commonSendButtonAction()
    }
    
    @objc func audioSendAction(){
        audioRecorderView.stopRecording()
        commonSendButtonAction()
        restoreDefaultView()
    }
    
    @objc func deleteAudioFile(){
        audioRecorderView.stopRecording()
        audioRecorderView.isDeleteAction = true
        if let audioURL = audioRecorderView.audioURL {
            let delete = ChatModel().discardAudioRecordings(fileURL: audioURL)
            switch delete {
            case .success(_):
                self.restoreDefaultView()
            case .failure(let error):
                AlerUser().alertUser(viewController: self, title: "Error", message: error.localizedDescription)
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
        audioRecorderView = AudioRecorderView(frame: CGRect(x: inputTextView.frame.origin.x, y: inputTextView.frame.origin.y, width: 270, height: 60))
        audioRecorderView.delegate = self
        audioRecorderView.layer.cornerRadius = 15
        audioRecorderView.layer.masksToBounds = true
        audioRecorderView.isHidden = true
        audioRecorderView.backgroundColor = .systemGray6
        view.addSubview(audioRecorderView)
        
        lockedAudioRecorderSendButton.frame = CGRect(x: sendButton.frame.origin.x + 10, y: view.frame.height - 40, width: 35, height: 35)
        lockedAudioRecorderSendButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        lockedAudioRecorderSendButton.addTarget(self, action: #selector(audioSendAction), for: .touchUpInside)
        lockedAudioRecorderSendButton.alpha = 0
        lockedAudioRecorderSendButton.tintColor = UIColorHex().hexStringToUIColor(hex: "#683BD8")
        self.view.addSubview(lockedAudioRecorderSendButton)
        
        lockedAudioRecorderDeleteButton.frame = CGRect(x: 40, y: view.frame.height - 40, width: 35, height: 35)
        lockedAudioRecorderDeleteButton.setImage(UIImage(systemName: "bin.xmark.fill"), for: .normal)
        lockedAudioRecorderDeleteButton.addTarget(self, action: #selector(deleteAudioFile), for: .touchUpInside)
        lockedAudioRecorderDeleteButton.alpha = 0
        lockedAudioRecorderDeleteButton.tintColor = .red
        self.view.addSubview(lockedAudioRecorderDeleteButton)
    }
    
    func updateAudioRecordingView(){
        audioRecorderView.frame = CGRect(x: 10, y: inputTextView.frame.origin.y, width: view.frame.width - 20, height: 100)
        sendButton.alpha = 0
        attachMedia.alpha = 0
        lockedAudioRecorderSendButton.alpha = 1
        lockedAudioRecorderDeleteButton.alpha = 1
        
    }
    
    func restoreDefaultView(){
        audioRecorderView.frame = CGRect(x: inputTextView.frame.origin.x, y: inputTextView.frame.origin.y, width: 270, height: 60)
        lockedAudioRecorderSendButton.alpha = 0
        lockedAudioRecorderDeleteButton.alpha = 0
        inputTextView.isHidden = false
        audioRecorderView.isHidden = true
        sendButton.alpha = 1
        attachMedia.alpha = 1
    }
    
    func setupAudioRecord(){
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleSendButtonLongPress(_:)))
        longPressGesture.delegate = self
        sendButton.addGestureRecognizer(longPressGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleSendButtonPanGesture(_:)))
        panGesture.delegate = self
        sendButton.addGestureRecognizer(panGesture)
    }
    
    func setupImageMessage(){
        attachMedia.setImage(UIImage(systemName: "paperclip"), for: .normal)
        attachMedia.frame = CGRect(x: inputTextView.frame.maxX - 40, y: inputTextView.frame.origin.y + 12, width: 30, height: 30)
        attachMedia.tintColor = .black
        attachMedia.addTarget(self, action: #selector(mediaShareAction), for: .touchDown)
        view.addSubview(attachMedia)
        
        imageMessageView.frame = CGRect(x: 20, y: 100, width: view.frame.width - 40, height: 600)
        imageMessageView.alpha = 0
        imageMessageView.delegate = self
        imageMessageView.layer.cornerRadius = 15
        view.addSubview(imageMessageView)
    }
    
    @objc func handleSendButtonLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        let location = gestureRecognizer.location(in: self.view)
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
            // We should not execute any cancle action if location is in audioRecorderView
            if audioRecorderView.frame.contains(location) {
                // If so, do nothing and return
                return
            }
            
            // Show input text view and hide record view
            audioRecorderView.stopRecording()
            sendButton.isEnabled = false
            self.inputTextView.isHidden = false
            self.audioRecorderView.isHidden = true
            self.sendButton.isEnabled = true

        default:
            break
        }
    }
    
    @objc func handleSendButtonPanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let button = gestureRecognizer.view as? UIButton else { return }
        let location = gestureRecognizer.location(in: self.view)
        
        switch gestureRecognizer.state {
        case .began:
            // When the pan gesture begins, store the initial touch point
            initialTouchPoint = location
            
            // Animate the button scaling and change its alpha
            UIView.animate(withDuration: 0.2) {
                button.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                button.alpha = 0.7
            }
            
        case .changed:
            // When the pan gesture changes, check if the touch point is inside the audioRecorderView
            if audioRecorderView.frame.contains(location) {
                // Ignore further actions if the touch point is inside the audioRecorderView
                UIView.animate(withDuration: 0.8) {
                    self.updateAudioRecordingView()
                }
                return
            }
            
            // Calculate the translation and limit it to the left side
            let translationX = (location.x - initialTouchPoint.x)
            var newCenterX = button.center.x + translationX
            
            // Limit the button's movement to the left side
            let minAllowedCenterX = view.frame.width - 23 - button.frame.width - 20 // Adjusted based on button's width
            let maxAllowedCenterX = minAllowedCenterX // Limiting movement only to the left side
            
            // Limit the button's movement to within the view's bounds
            newCenterX = min(maxAllowedCenterX, max(minAllowedCenterX, newCenterX))
            
            UIView.animate(withDuration: 0.8) {
                button.center = CGPoint(x: newCenterX, y: button.center.y)
            }
            
        case .ended, .cancelled, .failed:
            // Check if the touch point is inside the audioRecorderView
            if audioRecorderView.frame.contains(location) {
                // If so, do nothing and return
                return
            }
            
            // Show input text view and hide record view
            audioRecorderView.stopRecording()
            sendButton.isEnabled = false
            self.inputTextView.isHidden = false
            self.audioRecorderView.isHidden = true
            self.sendButton.isEnabled = true
            
            // Reset button image to "lock.open" with animation
            UIView.transition(with: self.sendButton, duration: 0.2, options: .transitionCrossDissolve, animations: {
                self.sendButton.setImage(UIImage(named: "lock.open"), for: .normal)
            }, completion: nil)
            
            // When the pan gesture ends or is canceled, reset the button's transform and alpha
            UIView.animate(withDuration: 0.2) {
                self.sendButton.transform = .identity
                self.sendButton.alpha = 1.0
                self.restoreDefaultView()
            }
            
        default:
            break
        }
    }
    
    @objc func mediaShareAction(){
        imageMessageView.setupPickerView(from: self)
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
            
            cell.delegate = self
            
            if message.sender.senderId == authUser.uid {
                cell.setCellData(audioURL: url, messageStatus: "\(dateFormatter.string(from: message.sentDate))", senderAvatarURL: authUser.photoURL, isCurrentUser: true, messageReadStatus: message.state)
            } else {
                cell.setCellData(audioURL: url, messageStatus: "\(dateFormatter.string(from: message.sentDate))", senderAvatarURL: senderPhotoURL, isCurrentUser: false)
            }
            return cell
        } else if case .photo(let image, let imageMessage) = message.kind {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "imageViewTableViewCell", for: indexPath) as? ImageViewTableViewCell else {
                return UITableViewCell()
            }
            
            if message.sender.senderId == authUser.uid {
                cell.setCellData(image: image, message: imageMessage, messageStatus: "\(dateFormatter.string(from: message.sentDate))", senderAvtar: authUser.photoURL, isCurrentUser: true, messageReadStatus: message.state)
            } else {
                cell.setCellData(image: image, message: imageMessage, messageStatus: "\(dateFormatter.string(from: message.sentDate))", senderAvtar: senderPhotoURL, isCurrentUser: false)
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let message = messages[indexPath.row]
        
        if case .photo(let image, let imageMessage) = message.kind {
            let duration:TimeInterval = 0.4
            if let cell = tableView.cellForRow(at: indexPath) as? ImageViewTableViewCell {
                let imageMessageViewRectInCell = cell.imageMessageView.convert(cell.imageMessageView.bounds, to: cell)
                let imageMessageViewRectInTableView = cell.convert(imageMessageViewRectInCell, to: tableView)
                if let superview = tableView.superview {
                    let imageMessageViewRectInMainFrame = tableView.convert(imageMessageViewRectInTableView, to: superview)
                    
                    expandedImageView.frame = messageTableView.bounds
                    UIView.animate(withDuration: duration) {
                        self.expandedImageView.alpha = 1
                    }
                    expandedImageView.showMessageView(imageURL: image, message: imageMessage, duration: duration)
                    expandedImageView.delegate = self
                    expandedImageView.expandToFullScreen(from: imageMessageViewRectInMainFrame, duration: duration)
                }
            }
        }
    }
}
 
extension ChatController : GrowingTextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        let textIsEmpty = textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        if textIsEmpty {
            sendButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
            attachMedia.alpha = 1
        } else {
            sendButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
            attachMedia.alpha = 0
        }
    }
}

extension ChatController: AudioMessageCellDelegate {
    func broadcastAlert(title: String, message: String) {
        AlerUser().alertUser(viewController: self, title: title, message: message)
    }
}

extension ChatController: AudioRecorderDelegate {
    func broadcastAudioURL(url: URL) {
        let sendAction = UIAlertAction(title: "Send", style: .default) { _ in
            ChatModel().sendAudioMessage(conversationID: self.conversationID ?? "", sender: self.authUser, audioURL: url) { error in
                if let error = error{
                    AlerUser().alertUser(viewController: self, title: "Error", message: error.description)
                }
            }
        }
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
            let delete = ChatModel().discardAudioRecordings(fileURL: url)
            
            switch delete {
            case .success(_):
                self.restoreDefaultView()
            case .failure(let error):
                AlerUser().alertUser(viewController: self, title: "Error", message: error.localizedDescription)
            }
        }
        
        var audioMessageActions:[UIAlertAction] = [sendAction, deleteAction]
        
        AlerUser().alertUser(viewController: self, title: "Audio Message", message: "Do you want to send audio message", actions: audioMessageActions)
    }
    
    func broadcastAlerts(title:String, message:String) {
        AlerUser().alertUser(viewController: self, title: title, message: message)
    }
}

extension ChatController:UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension ChatController: ImageMessageDelegate {
    func sendButtonCallBack(image: UIImage, message: String) {
        ChatModel().sendImageMessage(conversationID: conversationID ?? "", sender: authUser, image: image, message: message) { error in
            if let error = error {
                AlerUser().alertUser(viewController: self, title: "Error", message: error.description)
            }
            self.imageMessageView.alpha = 0
        }
    }
    
    func callForViewDisplay(displayView: Bool) {
        if displayView {
            UIView.animate(withDuration: 0.8) {
                self.imageMessageView.setupRecipientLable(recipient: self.senderUserName ?? "")
                self.imageMessageView.alpha = 1
            }
        } else {
            UIView.animate(withDuration: 0.8) {
                self.imageMessageView.alpha = 0
                self.expandedImageView.alpha = 0
            }
        }
    }
}
