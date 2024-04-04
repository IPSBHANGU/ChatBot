//
//  EmailSignINViewController.swift
//  Chatbot
//
//  Created by Umang Kedan on 20/03/24.
//

import UIKit
import FirebaseAuth
import NVActivityIndicatorView

class EmailSignINViewController: UIViewController {

    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var submitButton: UIButton!
    
    var activityIndicatorView: NVActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicatorView = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40), type: .ballClipRotateMultiple, color: .systemRed, padding: nil)
           activityIndicatorView.center = view.center
           activityIndicatorView.isHidden = true // Initially hidden
          
           view.addSubview(activityIndicatorView)
    }

    @IBAction func submitButtonAction(_ sender: Any) {
        self.activityIndicatorView.startAnimating()
        
        Auth.auth().signIn(withEmail: emailTextField.text ?? "", password: passwordTextField.text ?? "") { [weak self] result, error in
            guard let strongSelf = self else { return }
            if let error = error {
                AlerUser().alertUser(viewController: strongSelf, title: "Error", message: error.localizedDescription)
            } else {
                LoginModel().addUsersToDb(user: result?.user) { isSucceeded, error in
                    if let error = error {
                        AlerUser().alertUser(viewController: strongSelf, title: "Error", message: error)
                    } else if isSucceeded {
                        /*
                         * At this point User is Authenticated
                         * move to next View
                         */
                        let listChatView = ListChatViewController()
                        // pass whole result
                        listChatView.result = result
                        self?.activityIndicatorView.stopAnimating()
                        strongSelf.navigationController?.pushViewController(listChatView, animated: true)
                    }
                }
            }
        }
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension EmailSignINViewController:UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}

