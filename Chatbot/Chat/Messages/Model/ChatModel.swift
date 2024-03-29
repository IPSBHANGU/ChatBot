//
//  ChatModel.swift
//  Chatbot
//
//  Created by Umang Kedan on 21/03/24.
//

import FirebaseDatabaseInternal

struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
}

struct Sender: SenderType {
    var senderId: String
    var displayName: String
}

public enum MessageKind {
    case text(String)
}

public protocol MessageType {
  var sender: SenderType { get }
  var messageId: String { get }
  var sentDate: Date { get }
  var kind: MessageKind { get }
}

public protocol SenderType {
  var senderId: String { get }
  var displayName: String { get }
}

class ChatModel: NSObject {
    
    let messagesDatabase = Database.database().reference().child("conversation")
    
    /**
     func generateConversationID(user1ID: String, user2ID: String) -> String
     - Note: Used to generate a Unique String which will be used for generating unique chats between users.
     - parameter user1ID: User's (certainly sender)Unique UID generated after Successfull Authentication at firebase
     - parameter user2ID: User's (certainly other user)Unique UID generated after Successfull Authentication at firebase
     - returns: Sorted unique ID in String
     - warning: Do-not modify unless you have a better implementation
     */
    func generateConversationID(user1ID: String, user2ID: String) -> String {
        let sortedUserIDs = [user1ID, user2ID].sorted()
        let conversationID = sortedUserIDs.joined(separator: "_")
        return conversationID
    }
    
    func checkForUserRelation(conversationID: String, currentUserID: String) -> Bool{
            let userIDs = conversationID.components(separatedBy: "_")
            
            guard userIDs.count == 2 else {
                return false
            }
            
            if userIDs.first == currentUserID {
                return true
            } else if userIDs.last == currentUserID {
                return true
            } else {
                return false
            }
        }
    
    /**
     func getOtherUserID(conversationID: String, currentUserID: String) -> String?
     - Note: Used to get other user UID
     - parameter conversationID: expects unique ID generated by generateConversationID
     - parameter currentUserID: current Authenticated user UID
     - returns: other user's UID
     */
    func getOtherUserID(conversationID: String, currentUserID: String) -> String? {
        let userIDs = conversationID.components(separatedBy: "_")
        
        guard userIDs.count == 2 else {
            return nil
        }
        
        if let otherUserID = userIDs.first(where: { $0 != currentUserID }) {
            return otherUserID
        } else {
            return nil
        }
    }
    
    /**
     func sendMessage(conversationID: String, message: Message, completionHandler: @escaping (_ isSucceeded: Bool, _ error: String?) -> Void)
     - Note: Used to Send Meassages based on unique conversationID
     - parameter conversationID: Expected String, use ChatModel().generateConversationID
     - parameter message: Message format of type struct Message: MessageType {
                                              var sender: SenderType
                                              var messageId: String
                                              var sentDate: Date
                                              var kind: MessageKind
                                              var recipientID: String
                                            }
     - returns: Closure Function returns true if no error else gives error as String
     */
    func sendMessage(conversationID: String, senderID: String?, senderDisplayName: String?, message:String?, completionHandler: @escaping (_ error: String?) -> Void) {
        let messageRef = messagesDatabase.child(conversationID).childByAutoId()
        
        let newMessage = [
            "senderId": senderID ?? "",
            "displayName": senderDisplayName ?? "",
            "text": message ?? "",
            "sentDate": Date().timeIntervalSince1970
        ] as [String : Any]
        
        messageRef.setValue(newMessage) { (error, _) in
            if let error = error {
                completionHandler(error.localizedDescription)
            } else {
                completionHandler(nil)
            }
        }
    }
    
    /**
     func observeMessages(conversationID: String, currentUserID: String, otherUserID: String, completionHandler: @escaping ([Message]) -> Void)
     - Note: Used to Fetch Meassages based on unique conversationID
     - parameter conversationID: Expected String, use ChatModel().generateConversationID
     - parameter currentUserID: Authenticated User UID
     - parameter otherUserID: Other User UID
     - returns: returns meassage in format of struct Message: MessageType {
                                         var sender: SenderType
                                         var messageId: String
                                         var sentDate: Date
                                         var kind: MessageKind
                                         var recipientID: String
                                      }
     */
    func observeMessages(conversationID: String, currentUserID: String, otherUserID: String, completionHandler: @escaping ([Message]) -> Void) {
        var messages: [Message] = []
        messagesDatabase.child(conversationID).observe(.childAdded) { snapshot in
            guard let messageData = snapshot.value as? [String: Any] else {
                return
            }
            
            // Parse message data
            let senderId = messageData["senderId"] as? String ?? ""
            let displayName = messageData["displayName"] as? String ?? ""
            let text = messageData["text"] as? String ?? ""
            let sentDate = messageData["sentDate"] as? TimeInterval ?? 0
            
            // Create a Message object
            let message = Message(
                sender: Sender(senderId: senderId, displayName: displayName),
                messageId: snapshot.key,
                sentDate: Date(timeIntervalSince1970: sentDate),
                kind: .text(text)
            )
            messages.append(message)
            completionHandler(messages)
        }
    }
}
