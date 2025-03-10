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
import CoreLocation

struct AuthenticatedUser: Codable {
    var displayName: String?
    var email: String?
    var photoURL: String?
    var registeredDate: Date?
    var uid: String?
    var lastLocation: AuthenticatedUserLocation
}

struct AuthenticatedUserLocation: Codable {
    var latitude: String?
    var longitude: String?
}

/**
 - Note: Handle Error Senerios with more Explaintory Case
 */

enum ErrorCode: Int {
    case unKnownError = 1000
    case missingUserId = 1001
    case userAlreadyExists = 1002
    case databaseError = 1003
    case noMessage = 1004
    case noConversation = 1005
    case invalidData = 1006
    case locationServi = 1007
    
    var description: String {
        switch self {
        case .unKnownError:
            return "Unknown Error, Ask @IPSBHANGU why he is dumb"
        case .missingUserId:
            return "User ID is missing"
        case .userAlreadyExists:
            return "User already exists in the database"
        case .databaseError:
            return "Database error occurred"
        case .noMessage:
            return "No Message Found"
        case .noConversation:
            return "No Message Found"
        case .invalidData:
            return "Invalid Data Format from Database"
        case .locationServi:
            return "Location Services are Turned off"
        }
    }
}


class LoginModel: NSObject {
    
    let usersDatabase = Database.database().reference().child("users")
    
    func fetchUserDetails(userID: String, completion: @escaping (AuthenticatedUser?, Error?) -> Void) {
        let userRef = usersDatabase.child(userID)
        
        userRef.observeSingleEvent(of: .value) { snapshot   in
            guard let userData = snapshot.value as? [String: Any] else {
                completion(nil, "User data not found" as? Error)
                return
            }
            
            guard let displayName = userData["displayName"] as? String,
                  let email = userData["email"] as? String,
                  let photoURL = userData["photoURL"] as? String,
                  let uid = userData["uid"] as? String else {
                completion(nil, "Invalid user data" as? Error)
                return
            }
            
            var registeredDate: Date?
            if let timestamp = userData["registeredDate"] as? TimeInterval {
                registeredDate = Date(timeIntervalSince1970: timestamp)
            }
            
            var latitude:String?
            var longitude:String?
            if let lastLocation = userData["lastLocation"] as? [String: Any] {
                latitude = lastLocation["latitude"] as? String
                longitude = lastLocation["longitude"] as? String
            }
            
            let user = AuthenticatedUser(displayName: displayName, email: email, photoURL: photoURL, registeredDate: registeredDate, uid: uid, lastLocation: AuthenticatedUserLocation(latitude: latitude, longitude: longitude))
            completion(user, nil)
        }
    }
    
    func addUsersToDb(user:User?, displayName:String? = nil, photoURL:String? = nil, completionHandler: @escaping (_ isSucceeded: Bool, _ error: ErrorCode?) -> ()) {
        
        guard let userId = user?.uid else {
            completionHandler(false, .missingUserId)
            return
        }
        
        var displayName = displayName
        var photoURL = photoURL
        
        if let userDisplayName = user?.displayName, !userDisplayName.isEmpty {
            displayName = userDisplayName
        }
        
        if let userPhotoURL = user?.photoURL?.absoluteString, !userPhotoURL.isEmpty {
            photoURL = userPhotoURL
        }
        
        let db = usersDatabase.child(user?.uid ?? "")
        
        db.observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                completionHandler(false, .userAlreadyExists)
            } else {
                let newUser = [
                    "uid": user?.uid ?? "",
                    "displayName": displayName ?? "",
                    "email": user?.email ?? "",
                    "photoURL": photoURL ?? "",
                    "registeredDate": Date().timeIntervalSince1970,
                ] as [String : Any]
                
                db.setValue(newUser) { (error, _) in
                    if let error = error {
                        completionHandler(false, .databaseError)
                    } else {
                        completionHandler(true, nil)
                    }
                }
            }
        }
    }

    
    func fetchUsersFromDb(currentUserUID: String, completionHandler: @escaping ([Dictionary<String, Any>]?, String?) -> Void) {
        usersDatabase.observe(.value) { snapshot in
            guard let userData = snapshot.value as? [String: [String: Any]] else {
                completionHandler(nil, "No user data found")
                return
            }
            
            var usersList: [Dictionary<String, Any>] = []
            
            for (_, value) in userData {
                if let uid = value["uid"] as? String, uid != currentUserUID {
                    usersList.append(value)
                }
            }
            
            completionHandler(usersList, nil)
        } withCancel: { error in
            completionHandler(nil, error.localizedDescription)
        }
    }

    func connectUsers(authUserUID: String?, otherUserUID: String?, conversationID: String?, completionHandler: @escaping (_ isSucceeded: Bool, _ error: String?) -> ()) {
        
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
            
            var connectedUsers = authUserData["connectedUsers"] as? [String: [String:String]] ?? [:]
            connectedUsers[otherUserUID] = ["conversationID": conversationID ?? ""]
            
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
                        
                        var otherConnectedUsers = otherUserData["connectedUsers"] as? [String: [String:String]] ?? [:]
                        
                        otherConnectedUsers[authUserUID] = ["conversationID": conversationID ?? ""]
                        
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

    func fetchConnectedUsers(authUser: AuthenticatedUser?, completionHandler: @escaping ([Dictionary<String, Any>]?, String?) -> Void) {
        let db = usersDatabase.child(authUser?.uid ?? "").child("connectedUsers")
        
        db.observeSingleEvent(of: .value) { snapshot in
            guard let usersUID = snapshot.value as? [String: [String:String]] else {
                //completionHandler(nil, "No Users")
                return
            }
            
            var userDetailsArray: [[String: Any]] = []
            let dispatchGroup = DispatchGroup()
            
            for (userId, _) in usersUID {
                dispatchGroup.enter()
                
                self.fetchUserDetails(userID: userId) { userData, error in
                    defer {
                        dispatchGroup.leave()
                    }
                    
                    guard let userDetails = userData else {
                        //completionHandler(nil, "No Data")
                        return
                    }
                    
                    guard let conversationIDDict = usersUID[userId],
                          let conversationID = conversationIDDict["conversationID"] else {
                        completionHandler(nil, "Failed to convert conversationID")
                        return
                    }
                    
                    let modifiedConversationID = conversationID.replacingOccurrences(of: "conversationID:", with: "").trimmingCharacters(in: .whitespaces)
                    
                    let userDetailsDict: [String: Any] = [
                        "displayName": userDetails.displayName ?? "",
                        "email": userDetails.email ?? "",
                        "photoURL": userDetails.photoURL ?? "",
                        "uid": userDetails.uid ?? "",
                        "conversationID": modifiedConversationID
                    ]
                    
                    userDetailsArray.append(userDetailsDict)
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                completionHandler(userDetailsArray, nil)
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
    
    /**
     Updates the location of the authenticated user.

     - Parameters:
        - authUserUID: The UID of the authenticated user whose location will be updated.
        - locationCoordinate: The coordinate of the user's location represented as CLLocationCoordinate2D.
        - completionHandler: A closure to be called upon completion of the location update. This closure takes two parameters:
            - isSucceeded: A boolean indicating whether the location update was successful.
            - error: An optional ErrorCode describing an error encountered during the update, if any.

     - Important:
        This function updates the location of the authenticated user in the database.
     */
    func updateUserLocation(authUserUID: String?, locationCoordinate: CLLocationCoordinate2D, completionHandler: @escaping (_ isSucceeded: Bool, _ error: ErrorCode?) -> ()) {
        guard let authUserUID = authUserUID else {
            completionHandler(false, .missingUserId)
            return
        }
        
        let usersRef = Database.database().reference().child("users")
        
        // Update authUser's location
        usersRef.child(authUserUID).observeSingleEvent(of: .value) { authUserSnapshot  in
            guard var authUserData = authUserSnapshot.value as? [String: Any] else {
                completionHandler(false, .invalidData)
                return
            }
            
            // Update location data
            authUserData["lastLocation"] = ["latitude": locationCoordinate.latitude, "longitude": locationCoordinate.longitude]
            
            // Set updated user data
            usersRef.child(authUserUID).setValue(authUserData) { (error, _) in
                if let error = error {
                    completionHandler(false, .databaseError)
                } else {
                    completionHandler(true, nil)
                }
            }
        }
    }
    
    func fetchUserLocations(currentUserUID uid: String, completionHandler: @escaping ([AuthenticatedUser]?, String?) -> Void) {
        fetchUsersFromDb(currentUserUID: uid) { uIDs, error in
            if let error = error {
                completionHandler(nil, error)
                return
            }
            
            guard let uIDs = uIDs else {
                completionHandler(nil, "No user IDs found")
                return
            }
            
            var usersArr: [AuthenticatedUser] = [] // Initialize an empty array here
            
            // Use a recursive function to fetch user details
            func fetchNextUser(index: Int) {
                guard index < uIDs.count else {
                    // When all user details are fetched, call the completion handler
                    completionHandler(usersArr, nil)
                    return
                }
                
                let userID = uIDs[index]["uid"] as! String
                self.fetchUserDetails(userID: userID) { user, error in
                    if let error = error {
                        completionHandler(nil, error.localizedDescription)
                        return
                    }
                    
                    if let user = user {
                        usersArr.append(user) // Append the user to the array
                    }
                    
                    // Fetch details for the next user
                    fetchNextUser(index: index + 1)
                }
            }
            
            // Start fetching details for the first user
            fetchNextUser(index: 0)
        }
    }
}
