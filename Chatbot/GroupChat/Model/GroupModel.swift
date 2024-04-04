//
//  GroupModel.swift
//  Chatbot
//
//  Created by Umang Kedan on 24/03/24.
//

import Foundation
import FirebaseDatabaseInternal
import FirebaseAuth

struct GroupMessage: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
    var senderAvtar: String
}

class GroupModel: NSObject {
    
    let messagesDatabase = Database.database().reference().child("groupConversation")
    
    /**
     func generateGroupConversationID(authUserUID: [String]) -> String
     - Note: Used to generate a Unique String which will be used for generating unique chats between users.
     - parameter userIDs: User's Unique UID String Array generated after Successfull Authentication at firebase
     - returns: Sorted unique ID in String
     - warning: Do-not modify unless you have a better implementation
     */
    
    func generateGroupConversationID(authUserUID: String) -> String {
        let currentMilliseconds = Date().timeIntervalSince1970 * 1000
        let conversationID = authUserUID + String(format: "%.0f", currentMilliseconds)
        return conversationID
    }

    /**
     func connectUsersInGroupChatInDB(conversationID:String?, groupName:String?,  completionHandler: @escaping (_ isSucceeded: Bool, _ error: String?) -> ())
     - Note: Used to generate groups with users
     - parameter conversationID: expects unique ID in String generated by generateGroupConversationID
     - parameter groupName: expects String format and used for Naming Groups
     - returns: result if error returns a string and false else nil string and true
     */
    func connectUsersInGroupChatInDB(authUserUID:String?, conversationID:String?, groupName:String?, userIDs: [String],  completionHandler: @escaping (_ isSucceeded: Bool, _ error: String?) -> ()) {
        // Check if groupName is nil or empty
        guard let authUserUID = authUserUID, !authUserUID.isEmpty else {
            return
        }
        
        // Check if groupName is nil or empty
        guard let groupName = groupName, !groupName.isEmpty else {
            completionHandler(false, "Group name cannot be empty")
            return
        }
        
        // Check if conversationID is nil or empty
        guard let conversationID = conversationID, !conversationID.isEmpty else {
            completionHandler(false, "Group conversationID cannot be empty")
            return
        }
        
        let db = Database.database().reference().child("connectedUsersGroup").child(conversationID)
        
        let groupDetails = [
            "groupName": groupName,
            "groupAdmin": authUserUID,
            "groupMembers": userIDs
        ] as [String : Any]
        
        let newConnectedGroup = [
            "conversationID": conversationID,
            "groupDetails" : groupDetails
        ] as [String : Any]
        
        db.setValue(newConnectedGroup) { (error, _) in
            if let error = error {
                completionHandler(false, error.localizedDescription)
            } else {
                // Update users for group ConversationID
                let usersRef = Database.database().reference().child("users")
                
                // Update Admin User
                usersRef.child(authUserUID).observeSingleEvent(of: .value) { adminUserSnapshot in
                    guard var adminUserData = adminUserSnapshot.value as? [String: Any] else {
                        completionHandler(false, "Failed to get adminUserData")
                        return
                    }
                    
                    var connectedGroups = adminUserData["connectedGroups"] as? [String] ?? []
                    connectedGroups.append(conversationID)
                    
                    adminUserData["connectedGroups"] = connectedGroups
                    
                    usersRef.child(authUserUID).setValue(adminUserData) { (error, _) in
                        if let error = error {
                            completionHandler(false, error.localizedDescription)
                        } else {
                            // Update otherUsers
                            let dispatchGroup = DispatchGroup()
                            
                            for userID in userIDs {
                                dispatchGroup.enter()
                                
                                usersRef.child(userID).observeSingleEvent(of: .value) { otherUserSnapshot in
                                    defer {
                                        dispatchGroup.leave()
                                    }
                                    
                                    guard var otherUserID = otherUserSnapshot.value as? [String: Any] else {
                                        completionHandler(false, "Failed to get otherUserData")
                                        return
                                    }
                                    
                                    var connectedGroups = otherUserID["connectedGroups"] as? [String] ?? []
                                    connectedGroups.append(conversationID)
                                    
                                    otherUserID["connectedGroups"] = connectedGroups
                                    
                                    usersRef.child(userID).setValue(otherUserID) { (error, _) in
                                        if let error = error {
                                            completionHandler(false, error.localizedDescription)
                                        }
                                    }
                                }
                            }
                            
                            dispatchGroup.notify(queue: .main) {
                                completionHandler(true, nil)
                            }
                        }
                    }
                }
            }
        }
    }
    
    /**
     func fetchConnectedUsersInGroupChatInDB(userId: String, completion: @escaping ([Dictionary<String, Any>]?, Error?) -> Void)
     - Note: Used to generate groups with users
     - parameter conversationID: expects unique ID in String generated by generateGroupConversationID
     - parameter groupName: expects String format and used for Naming Groups
     - returns: result if error returns a string and false else nil string and true
     */
    
    func fetchConnectedUsersInGroupChatInDB(userId: String, completion: @escaping ([Dictionary<String, Any>]?, Error?) -> Void) {
        let dbRef = Database.database().reference().child("connectedUsersGroup")
        
        dbRef.observeSingleEvent(of: .value) { snapshot in
            var groups: [Dictionary<String, Any>] = []
            
            for child in snapshot.children {
                if let groupSnapshot = child as? DataSnapshot,
                   let groupData = groupSnapshot.value as? [String: Any],
                   let groupName = groupData["groupName"] as? String,
                   let conversationId = groupData["conversationID"] as? String {
                    
                    // Check if the authenticated user's UID is part of the group
                    if conversationId.contains(userId) {
                        let group: [String: Any] = ["groupName": groupName, "conversationID": conversationId]
                        groups.append(group)
                    }
                }
            }
            
            completion(groups, nil)
        } withCancel: { error in
            completion(nil, error)
        }
    }
    
    /**
     func sendGroupMessage(conversationID: String, message: Message, completionHandler: @escaping (_ isSucceeded: Bool, _ error: String?) -> Void)
     - Note: Used to Send Meassages based on unique conversationID
     - parameter conversationID: Expected String, use ChatModel().generateConversationID
     - parameter sender: Expected User? Object
     - parameter message: Message format of type struct Message: MessageType {
                                              var sender: SenderType
                                              var messageId: String
                                              var sentDate: Date
                                              var kind: MessageKind
                                              var recipientID: String
                                            }
     - returns: Closure Function returns true if no error else gives error as String
     */
    func sendGroupMessage(conversationID: String, sender: AuthenticatedUser?, message:String?, completionHandler: @escaping (_ error: String?) -> Void) {
        let messageRef = messagesDatabase.child(conversationID).childByAutoId()
        
        let newMessage = [
            "senderId": sender?.uid ?? "",
            "displayName": sender?.displayName ?? "",
            "text": message ?? "",
            "sentDate": Date().timeIntervalSince1970,
            "photoURL": sender?.photoURL ?? ""
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
     - returns: returns meassage in format of struct Message: MessageType {
                                         var sender: SenderType
                                         var messageId: String
                                         var sentDate: Date
                                         var kind: MessageKind
                                         var recipientID: String
                                      }
     */
    func observeGroupMessages(conversationID: String, currentUserID: String, completionHandler: @escaping ([GroupMessage]) -> Void) {
        var messages: [GroupMessage] = []
        messagesDatabase.child(conversationID).observe(.childAdded) { snapshot in
            guard let messageData = snapshot.value as? [String: Any] else {
                return
            }
            
            // Parse message data
            let senderId = messageData["senderId"] as? String ?? ""
            let displayName = messageData["displayName"] as? String ?? ""
            let photoURL = messageData["photoURL"] as? String ?? ""
            let text = messageData["text"] as? String ?? ""
            let sentDate = messageData["sentDate"] as? TimeInterval ?? 0
            
            // Create a Message object
            let message = GroupMessage(
                sender: Sender(senderId: senderId, displayName: displayName),
                messageId: snapshot.key,
                sentDate: Date(timeIntervalSince1970: sentDate),
                kind: .text(text),
                senderAvtar: photoURL
            )
            messages.append(message)
            completionHandler(messages)
        }
    }
}
