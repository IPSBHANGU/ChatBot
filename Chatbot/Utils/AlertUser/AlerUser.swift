//
//  AlerUser.swift
//  APiDemo
//
//  Created by Inderpreet Singh on 28/02/24.
//

import Foundation
import UIKit

class AlerUser:NSObject {
    /*
     Accepts 4 arguements
     title as String for title of alert
     message as String for alert meassage
     view as UIViewController
     Optional arguement to pass custom UIAlertAction usefull if need to add any function at alert action
     */
    func alertUser(viewController: UIViewController, title: String, message: String, action: UIAlertAction? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        if let action = action {
            alert.addAction(action)
        } else {
            let defaultAction = UIAlertAction(title: "Okay", style: .default)
            alert.addAction(defaultAction)
        }
        
        viewController.present(alert, animated: true)
    }

}
