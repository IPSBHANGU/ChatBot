//
//  AlerUser.swift
//  APiDemo
//
//  Created by Umang Kedan on 28/02/24.
//

import Foundation
import UIKit

class AlerUser:NSObject {
    /*
     Accepts 4 arguements
     title as String for title of alert
     message as String for alert meassage
     view as UIViewController
     Optional arguement to pass custom UIAlertAction Array usefull if need to add any function at alert action
     */
    func alertUser(viewController: UIViewController, title: String, message: String, actions: [UIAlertAction]? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.view.tintColor = .black
        
        if let actions = actions {
            for action in actions {
                alert.addAction(action)
            }
        } else {
            let defaultAction = UIAlertAction(title: "Okay", style: .default)
            alert.addAction(defaultAction)
        }
        
        viewController.present(alert, animated: true)
    }


}
