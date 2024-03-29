//
//  GoogleAuth.swift
//  SocialSignIN
//
//  Created by Umang Kedan on 06/03/24.
//

import Foundation
import UIKit
import GoogleSignIn

class GoogleAuth:NSObject {
    
    func signIN(viewController: UIViewController, completionHandler: @escaping (_ isSucceeded: Bool, _ data: GIDSignInResult?, _ error: String?) -> ()) {
        GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { signInResult, error in
            guard let signInResult = signInResult else {
                completionHandler(false, nil, "Failed logined into google account")
                return
            }
            // Fix my mistake, if user is authenticated we should never return error
            // this results in function calling model fuction to always gives an alert
            // even if user is authenticated
//            completionHandler(true, signInResult, "SuccessFully logined into google account")
            completionHandler(true, signInResult, nil)
        }
    }
    
    func signOUT(){
        GIDSignIn.sharedInstance.signOut()
    }
}
