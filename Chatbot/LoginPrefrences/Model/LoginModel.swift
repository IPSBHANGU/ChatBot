//
//  LoginModel.swift
//  Chatbot
//
//  Created by Inderpreet Singh on 22/03/24.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase

struct FirebaseUser:Codable {
    var displayName: String?
    var email: String?
    var photoURl: String?
}

class LoginModel:NSObject {
    
    let usersDatabase = Database.database().reference().child("users")
    
    func addUsersToDb(user:User?, completionHandler: @escaping (_ isSucceeded: Bool, _ error: String?) -> ()) {

        let db = usersDatabase.child(user?.uid ?? "")
        let newUser = [
            "uid": user?.uid ?? "",
            "displayName": user?.displayName ?? "",
            "email": user?.email ?? "",
            "photoURL": user?.photoURL?.absoluteString ?? "",
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

    
    func fetchConnectedUsersInDB(authUser: User?, completionHandler: @escaping ([Dictionary<String, Any>]?, String?) -> Void) {
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
                if let reversedUID = ChatModel().getOtherUserID(conversationID: id, currentUserID: authUser?.uid ?? "") {
                    uidArray.append(reversedUID)
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
}
