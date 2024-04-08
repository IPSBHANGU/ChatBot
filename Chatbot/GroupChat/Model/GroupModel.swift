//
//  GroupModel.swift
//  Chatbot
//
//  Created by Umang Kedan on 24/03/24.
//

import Foundation
import FirebaseDatabaseInternal
import FirebaseAuth
import UIKit
import FirebaseStorage

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

    // Function to upload image to Firebase Storage
    func uploadGroupAvtar(groupAvtar: UIImage?, conversationID: String?, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let imageData = groupAvtar?.jpegData(compressionQuality: 0.5) else {
            completion(.failure("Error: Unable to convert image to data" as! Error))
            return
        }
        
        guard let conversationID = conversationID else {
            completion(.failure("Error: group conversation ID is nil" as! Error))
            return
        }

        let storageRef = Storage.storage().reference().child("group_avtar").child("\(conversationID).jpg")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        storageRef.putData(imageData, metadata: metadata) { (metadata, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(true))
            }
        }
    }
    
    // Function to download image to Firebase Storage
    func downloadGroupAvtarURL(conversationID: String?, completionHandler: @escaping (Bool?, String?) -> Void) {
        guard let conversationID = conversationID else {
            completionHandler(false, "Error: conversation ID is nil")
            return
        }
        
        let storageRef = Storage.storage().reference().child("group_avtar").child("\(conversationID).jpg")
        
        storageRef.downloadURL { (url, error) in
            if let error = error {
                completionHandler(false, "Error getting download URL: \(error.localizedDescription)")
                return
            }
            
            completionHandler(true, url?.absoluteString)
        }
    }
    
    /**
     func connectUsersInGroupChatInDB(conversationID:String?, groupName:String?,  completionHandler: @escaping (_ isSucceeded: Bool, _ error: String?) -> ())
     - Note: Used to generate groups with users
     - parameter conversationID: expects unique ID in String generated by generateGroupConversationID
     - parameter groupName: expects String format and used for Naming Groups
     - returns: result if error returns a string and false else nil string and true
     */
    func connectUsersInGroupChatInDB(authUserUID:String?, conversationID:String?, groupName:String?, groupAvtar:UIImage?, userIDs: [String],  completionHandler: @escaping (_ isSucceeded: Bool, _ error: String?) -> ()) {
        // Check if groupName is nil or empty
        guard let authUserUID = authUserUID, !authUserUID.isEmpty else {
            return
        }
        
        // Check if groupName is nil or empty
        guard let groupName = groupName, !groupName.isEmpty else {
            completionHandler(false, "Group name cannot be empty")
            return
        }
        
        // Check if groupAvtar is nil
        guard let groupAvtar = groupAvtar else {
            completionHandler(false, "Group photo cannot be nil")
            return
        }
        
        // Check if conversationID is nil or empty
        guard let conversationID = conversationID, !conversationID.isEmpty else {
            completionHandler(false, "Group conversationID cannot be empty")
            return
        }
        
        // Check if UserIDArray is nil
        if userIDs.isEmpty {
            completionHandler(false, "empty member users")
            return
        }
        
        uploadGroupAvtar(groupAvtar: groupAvtar, conversationID: conversationID) { status in
            switch status {
            case .failure(let error):
                completionHandler(false, "Error uploading avatar: \(error.localizedDescription)")
            case .success(_):
                self.downloadGroupAvtarURL(conversationID: conversationID) { is_Success, url in
                    if is_Success == true {
                        guard let groupURL = url else {
                            completionHandler(false, "Failed to get groupAvtar from Database")
                            return
                        }
                        let db = Database.database().reference().child("connectedUsersGroup").child(conversationID)
                        
                        let groupDetails = [
                            "groupName": groupName,
                            "groupAvtar": groupURL,
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
    
    func fetchConnectedUsersInGroupChatInDB(authUser: AuthenticatedUser?, completionHandler: @escaping ([[String: Any]]?, String?) -> Void) {
        
        guard let authUserID = authUser?.uid else {
            completionHandler(nil, "Authenticated user ID is missing")
            return
        }
        
        let db = Database.database().reference().child("users").child(authUserID).child("connectedGroups")
        
        db.observeSingleEvent(of: .value) { snapshot in
            guard let groupsID = snapshot.value as? [String] else {
                completionHandler(nil, "No connected groups found")
                return
            }
            
            var groupDetailsArray: [[String: Any]] = []
            let dispatchGroup = DispatchGroup()
            
            for groupID in groupsID {
                dispatchGroup.enter()
                let groupDB = Database.database().reference().child("connectedUsersGroup").child(groupID)
                
                groupDB.observeSingleEvent(of: .value) { snapshot in
                    defer {
                        dispatchGroup.leave()
                    }
                    
                    guard let groupData = snapshot.value as? [String:Any] else {
                        return
                    }
                    
                    let groupDetails:[String: Any] = groupData["groupDetails"] as! [String : Any]
                    
                    let groupName = groupDetails["groupName"] as? String ?? ""
                    let groupAdmin = groupDetails["groupAdmin"] as? String ?? ""
                    let groupAvtar = groupDetails["groupAvtar"] as? String ?? ""
                    let groupMembers = groupDetails["groupMembers"] as? [String] ?? []
                    
                    let groupDetailsDict: [String: Any] = [
                        "conversationID": groupData["conversationID"] as? String ?? "",
                        "groupName": groupName,
                        "groupAvtar": groupAvtar,
                        "groupAdmin": groupAdmin,
                        "groupMembers": groupMembers
                    ]
                    
                    groupDetailsArray.append(groupDetailsDict)
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                completionHandler(groupDetailsArray, nil)
            }
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
    func observeGroupMessages(conversationID: String, completionHandler: @escaping ([GroupMessage]?, _ error: ErrorCode?) -> Void) {
        var messages: [GroupMessage] = []
        messagesDatabase.child(conversationID).observe(.childAdded) { snapshot in
            guard let messageData = snapshot.value as? [String: Any] else {
                completionHandler(nil, .noMessage)
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
            completionHandler(messages, nil)
        }
    }
    
    func fetchGroupUsersDetails(members:[String], completionHandler: @escaping ([Dictionary<String, Any>]?, String?) -> Void) {
        var userDetailsArray: [[String: Any]] = []
        let dispatchGroup = DispatchGroup()
        
        for member in members {
            dispatchGroup.enter()
            LoginModel().fetchUserDetails(userID: member) { user, error in
                defer {
                    dispatchGroup.leave()
                }
                
                guard let userDetails = user else {
                    return
                }
                
                let userDetailsDict: [String: Any] = [
                    "displayName": userDetails.displayName ?? "",
                    "email": userDetails.email ?? "",
                    "photoURL": userDetails.photoURL ?? "",
                    "uid": userDetails.uid ?? "",
                ]
                userDetailsArray.append(userDetailsDict)
            }
        }
        dispatchGroup.notify(queue: .main) {
            completionHandler(userDetailsArray, nil)
        }
    }
    
    // Function to remove a specific message from a conversation
     func removeChildNodeFromConversation(conversationId: String, messageId: String, completionHandler: @escaping (_ isSucceeded: Bool, _ error: String?) -> ()) {

         let messageIdRef = messagesDatabase.child(conversationId).child(messageId)

         messageIdRef.removeValue { error, _ in
             if let error = error {
                 completionHandler(false, error.localizedDescription)
             } else {
                 completionHandler(true, nil)
             }
         }
     }
    
    func checkConversation(conversationID: String, completionHandler: @escaping (_ isSucceeded: Bool, _ error: ErrorCode?) -> Void) {
        messagesDatabase.child(conversationID).observeSingleEvent(of: .value) { snapshot in
            guard snapshot.exists() else {
                completionHandler(false, .noConversation)
                return
            }
            completionHandler(true, nil)
        }

    }
    
    /**
      Updates the list of connected groups for the specified authenticated user.
      This function fetches connected groups from the `fetchConnectedUsersInGroupChatInDB` using the provided `authUserUID`. It processes each user to gather additional details such as conversation information and last message details before invoking the completion handler.
      - Parameters:
        - authUserUID: The authenticated user for whom connected users are being updated.
        - completionHandler: A closure to be called when the update operation completes. It provides an array of group details dictionaries and an optional error message in case of failure.
          - Parameter groups: An array of dictionaries containing details of connected groups.
          - Parameter error: An optional error message indicating the reason for failure, if any.
      */
     func updateConnectedGroup(authUserUID: AuthenticatedUser?, completionHandler: @escaping ([Dictionary<String, Any>]?, String?) -> Void) {
         guard let authUser = authUserUID else {
             completionHandler(nil, "Authenticated user is nil")
             return
         }

         self.fetchConnectedUsersInGroupChatInDB(authUser: authUser, completionHandler: { groups, error in
             if let error = error {
                 completionHandler(nil, "Failed to fetch connected users: \(error)")
                 return
             }

             guard let groups = groups else {
                 completionHandler(nil, "No groups")
                 return
             }

             self.processGroups(groups: groups, index: 0, groupArray: [], completionHandler: completionHandler)
         })
     }
                                                 
    /**
     Recursively processes a list of groups to gather additional details like conversation and last message information.
     This function iteratively processes each group in the given `groups` array, retrieves conversation and message details asynchronously, and constructs group details dictionaries with the gathered information.
     - Parameters:
       - groups: An array of dictionaries representing groups to be processed.
       - index: The current index of the user being processed.
       - groupArray: An array containing dictionaries of group details accumulated during processing.
       - completionHandler: A closure to be called when user processing completes for all groups or encounters an error.
         - Parameter userArray: An array of dictionaries containing details of processed users.
         - Parameter error: An optional error message indicating the reason for failure, if any.
     */
    private func processGroups(groups: [Dictionary<String, Any>], index: Int, groupArray: [[String: Any]], completionHandler: @escaping ([Dictionary<String, Any>]?, String?) -> Void) {
        if index >= groups.count {
            completionHandler(groupArray, nil)
            return
        }

        let group = groups[index]

        self.checkConversation(conversationID: group["conversationID"] as? String ?? "") { isSucceeded, error in
            if let error = error {
                switch error {
                case .noConversation:
                    let groupDetailsDict: [String: Any] = [
                        "conversationID": group["conversationID"] as? String ?? "",
                        "groupName": group["groupName"] as? String ?? "",
                        "groupAdmin": group["groupAdmin"] as? String ?? "",
                        "groupAvtar": group["groupAvtar"] as? String ?? "",
                        "groupMembers": group["groupMembers"] as? [String] ?? []
                    ]
                    var updatedGroupArray = groupArray
                    updatedGroupArray.append(groupDetailsDict)

                    self.processGroups(groups: groups, index: index + 1, groupArray: updatedGroupArray, completionHandler: completionHandler)

                default:
                    completionHandler(nil, error.description)
                }
            } else if isSucceeded {
                self.observeGroupMessages(conversationID: group["conversationID"] as? String ?? "", completionHandler: { messages, observeError in
                    if let observeError = observeError {
                        completionHandler(nil, "Error observing messages: \(observeError)")
                        return
                    }

                    if let lastMessage = messages?.last {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "h:mm a"
                        let dateString = formatter.string(from: lastMessage.sentDate)

                        let groupDetailsDict: [String: Any] = [
                            "conversationID": group["conversationID"] as? String ?? "",
                            "groupName": group["groupName"] as? String ?? "",
                            "groupAdmin": group["groupAdmin"] as? String ?? "",
                            "groupAvtar": group["groupAvtar"] as? String ?? "",
                            "groupMembers": group["groupMembers"] as? [String] ?? [],
                            "lastMessage": lastMessage.kind,
                            "lastMessageTime": dateString,
                            "lastMessageSender": lastMessage.sender
                        ]

                        var updatedGroupArray = groupArray
                        updatedGroupArray.append(groupDetailsDict)

                        self.processGroups(groups: groups, index: index + 1, groupArray: updatedGroupArray, completionHandler: completionHandler)
                    } else {
                        self.processGroups(groups: groups, index: index + 1, groupArray: groupArray, completionHandler: completionHandler)
                    }
                })
            }
        }
    }
}
