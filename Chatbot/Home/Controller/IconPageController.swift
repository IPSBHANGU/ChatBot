//
//  IconPageController.swift
//  Chatbot
//
//  Created by Umang Kedan on 26/03/24.
//

import UIKit
import NVActivityIndicatorView
import FirebaseAuth

class IconPageController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let activityIndicator = NVActivityIndicatorView(frame: CGRect(x: 170, y: 600, width: 60, height: 60))
        activityIndicator.color = .purple
        activityIndicator.type = .ballClipRotatePulse
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            activityIndicator.stopAnimating()
            activityIndicator.removeFromSuperview()
            if Auth.auth().currentUser != nil {
               // self.navigateToListController()
            } else {
                //self.navigateLoginController()
            }
        }
    }
    
//    private func navigateToListController() {
//        guard let listController = UIStoryboard(name: "Main", bundle: .main).instantiateViewController(withIdentifier: "listController") as? ListController else {
//            print("Failed to instantiate ListController")
//            return
//        }
//        if let displayName = Auth.auth().currentUser?.displayName {
//            listController.name = displayName
//        }
//        navigationController?.pushViewController(listController, animated: true)
//    }

}
