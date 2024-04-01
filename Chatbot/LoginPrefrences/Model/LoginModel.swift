//
//  LoginModel.swift
//  Chatbot
//
//  Created by Umang Kedan on 22/03/24.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase
import UIKit
import FirebaseStorage

struct AuthenticatedUser: Codable {
    var displayName: String?
    var email: String?
    var photoURL: String?
    var uid: String?
}

class LoginModel: NSObject {
    
    let usersDatabase = Database.database().reference().child("users")
    
    func fetchUserDetails(userID: String, completion: @escaping (AuthenticatedUser?, Error?) -> Void) {
        let userRef = usersDatabase.child(userID)
        
        userRef.observeSingleEvent(of: .value) { snapshot in
            guard let userData = snapshot.value as? [String: Any] else {
                completion(nil, "User data not found" as? Error)
                return
            }
            
            guard let displayName = userData["displayName"] as? String,
                  let email = userData["email"] as? String,
                  let photoURL = userData["photoURL"] as? String,
                  let uid = userData["uid"] as? String else {
                completion(nil, NSError(domain: "com.yourapp", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid user data"]))
                return
            }
            
            let user = AuthenticatedUser(displayName: displayName, email: email, photoURL: photoURL, uid: uid)
            completion(user, nil)
        }
    }
    
    func addUsersToDb(user:User?, displayName:String? = nil, photoURL:String? = nil, completionHandler: @escaping (_ isSucceeded: Bool, _ error: String?) -> ()) {
        var displayName = displayName
        var photoURL = photoURL
        
        if let userDisplayName = user?.displayName, !userDisplayName.isEmpty {
            displayName = userDisplayName
        }
        
        if let userPhotoURL = user?.photoURL?.absoluteString, !userPhotoURL.isEmpty {
            photoURL = userPhotoURL
        }
        
        let db = usersDatabase.child(user?.uid ?? "")
        let newUser = [
            "uid": user?.uid ?? "",
            "displayName": displayName ?? "",
            "email": user?.email ?? "",
            "photoURL": photoURL ?? "",
            "registeredDate": Date().timeIntervalSince1970,
        ] as [String : Any]
        
        db.setValue(newUser) { (error, _) in
            if let error = error {
                completionHandler(false, error.localizedDescription)
            } else {
                completionHandler(true, nil)
            }
        }
    }

    
    func fetchUsersFromDb(completionHandler: @escaping ([Dictionary<String, Any>]?, String?) -> Void) {
        usersDatabase.observe(.value) { snapshot in
            guard let userData = snapshot.value as? [String: [String: Any]] else {
                completionHandler(nil, "No user data found")
                return
            }
            
            var usersList: [Dictionary<String, Any>] = []
            
            for (_, value) in userData {
                usersList.append(value) // Append each user's data to the usersList
            }
            
            completionHandler(usersList, nil)
        } withCancel: { error in
            completionHandler(nil, error.localizedDescription)
        }
    }
    
    func connectUsersInDB(authUserUID: String?, otherUserUID:String?, conversationID:String?, completionHandler: @escaping (_ isSucceeded: Bool, _ error: String?) -> ()) {

        let db = Database.database().reference().child("connectedUsers").child("conversationID: \(conversationID ?? "")")
        let newConnectedUser = [
            "User1": authUserUID ?? "",
            "User2": otherUserUID ?? ""
        ] as [String : Any]
        
        db.setValue(newConnectedUser) { (error, _) in
            if let error = error {
                completionHandler(false, error.localizedDescription)
            } else {
                completionHandler(true, nil)
            }
        }
    }

    func addUsers(authUserUID: String?, otherUserUID: String?, conversationID: String?, completionHandler: @escaping (_ isSucceeded: Bool, _ error: String?) -> ()) {
        
        guard let authUserUID = authUserUID, let otherUserUID = otherUserUID else {
            completionHandler(false, "authUserUID or otherUserUID is nil")
            return
        }
        
        let usersRef = Database.database().reference().child("users")
        
        // Update authUser's connected users
        usersRef.child(authUserUID).observeSingleEvent(of: .value) { authUserSnapshot in
            guard var authUserData = authUserSnapshot.value as? [String: Any] else {
                completionHandler(false, "Failed to get authUserData")
                return
            }
            
            var connectedUsers = authUserData["connectedUsers"] as? [String:Any] ?? [:]
            connectedUsers.updateValue(conversationID ?? "", forKey: otherUserUID)
            
            authUserData["connectedUsers"] = connectedUsers
            
            usersRef.child(authUserUID).setValue(authUserData) { (error, _) in
                if let error = error {
                    completionHandler(false, error.localizedDescription)
                } else {
                    // Update otherUser's connected users
                    usersRef.child(otherUserUID).observeSingleEvent(of: .value) { otherUserSnapshot in
                        guard var otherUserData = otherUserSnapshot.value as? [String: Any] else {
                            completionHandler(false, "Failed to get otherUserData")
                            return
                        }
                        
                        var otherConnectedUsers = otherUserData["connectedUsers"] as? [String:Any] ?? [:]
                        otherConnectedUsers.updateValue(conversationID ?? "", forKey: authUserUID)
                        
                        otherUserData["connectedUsers"] = otherConnectedUsers
                        
                        usersRef.child(otherUserUID).setValue(otherUserData) { (error, _) in
                            if let error = error {
                                completionHandler(false, error.localizedDescription)
                            } else {
                                completionHandler(true, nil)
                            }
                        }
                    } withCancel: { error in
                        completionHandler(false, error.localizedDescription)
                    }
                }
            }
        } withCancel: { error in
            completionHandler(false, error.localizedDescription)
        }
    }
    
    func fetchConnectedUsersconversationID(completionHandler: @escaping ([String]?, String?) -> Void) {
        let db = Database.database().reference().child("connectedUsers")
        
        db.observeSingleEvent(of: .value) { snapshot in
            guard let userData = snapshot.value as? [String: Any] else {
                completionHandler(nil, "No Users")
                return
            }
            
            var conversationIDs: [String] = []
            
            for (conversationID, _) in userData {
                let cleanConversationID = conversationID.replacingOccurrences(of: "conversationID:", with: "").trimmingCharacters(in: .whitespaces)
                conversationIDs.append(cleanConversationID)
            }
            completionHandler(conversationIDs, nil)
        } withCancel: { error in
            completionHandler(nil, error.localizedDescription)
        }
    }

    
    func fetchConnectedUsersInDB(authUser: AuthenticatedUser?, completionHandler: @escaping ([Dictionary<String, Any>]?, String?) -> Void) {
        fetchConnectedUsersconversationID { conversationIDs, error in
            if let error = error {
                completionHandler(nil, error)
                return
            }
            
            guard let ids = conversationIDs else {
                completionHandler(nil, "No IDs found")
                return
            }
            
            var uidArray:[String] = []
            
            for id in ids {
                let check = ChatModel().checkForUserRelation(conversationID: id, currentUserID: authUser?.uid ?? "")
                if check == true {
                    if let reversedUID = ChatModel().getOtherUserID(conversationID: id, currentUserID: authUser?.uid ?? "") {
                        uidArray.append(reversedUID)
                    }
                }
            }
            
            self.usersDatabase.observeSingleEvent(of: .value) { snapshot in
                guard let userData = snapshot.value as? [String: Any] else {
                    completionHandler(nil, "No user data found")
                    return
                }
                
                var usersList: [Dictionary<String, Any>] = []
                
                for uid in uidArray {
                    if let user = userData[uid] as? [String: Any] {
                        usersList.append(user)
                    }
                }
                completionHandler(usersList, nil)
            }
        }
    }
    
    // Function to upload image to Firebase Storage
    func uploadUserAvtar(userAvtar: UIImage?, currentUser: User?, completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let imageData = userAvtar?.jpegData(compressionQuality: 0.5) else {
            completion(.failure("Error: Unable to convert image to data" as! Error))
            return
        }
        
        guard let currentUserID = currentUser?.uid else {
            completion(.failure("Error: User ID is nil" as! Error))
            return
        }

        let storageRef = Storage.storage().reference().child("profile_images").child("\(currentUserID).jpg")

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
    func downloadUserAvtarURL(currentUser: User?, completionHandler: @escaping (Bool?, String?) -> Void) {
        guard let currentUserID = currentUser?.uid else {
            completionHandler(false, "Error: User ID is nil")
            return
        }
        
        let storageRef = Storage.storage().reference().child("profile_images").child("\(currentUserID).jpg")
        
        storageRef.downloadURL { (url, error) in
            if let error = error {
                completionHandler(false, "Error getting download URL: \(error.localizedDescription)")
                return
            }
            
            completionHandler(true, url?.absoluteString)
        }
    }
}
