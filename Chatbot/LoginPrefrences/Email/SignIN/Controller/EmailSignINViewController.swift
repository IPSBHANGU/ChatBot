//
//  EmailSignINViewController.swift
//  Chatbot
//
//  Created by Inderpreet Singh on 20/03/24.
//

import UIKit
import FirebaseAuth

class EmailSignINViewController: UIViewController {

    lazy var emailTextFieldView = UIView()
    lazy var emailTextField = UITextField()
    lazy var passwordTextFieldView = UIView()
    lazy var passwordTextField = UITextField()
    lazy var submitSignINButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupUI()
    }


    func setupUI(){
        emailTextField.placeholder = "Email Address"
        passwordTextField.placeholder = "Password"
        
        emailTextFieldView.frame = CGRect(x: 24, y: view.frame.width - 160, width: view.frame.width - 44, height: 40)
        emailTextField.frame = CGRect(x: 2, y: 0, width: emailTextFieldView.frame.width, height: emailTextFieldView.frame.height)
        
        passwordTextFieldView.frame = CGRect(x: 24, y: view.frame.width - 100, width: view.frame.width - 44, height: 40)
        passwordTextField.frame = CGRect(x: 2, y: 0, width: passwordTextFieldView.frame.width, height: passwordTextFieldView.frame.height)
        passwordTextField.isSecureTextEntry = true
        
        emailTextField.tintColor = .black
        emailTextFieldView.layer.cornerRadius = 9.0
        emailTextFieldView.layer.borderColor = UIColor.black.cgColor
        emailTextFieldView.layer.borderWidth = 2.0
        passwordTextField.tintColor = .black
        passwordTextFieldView.layer.cornerRadius = 9.0
        passwordTextFieldView.layer.borderColor = UIColor.black.cgColor
        passwordTextFieldView.layer.borderWidth = 2.0
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        submitSignINButton.setTitle("Submit", for: .normal)
        submitSignINButton.addTarget(self, action: #selector(submitSignINButtonAction), for: .touchUpInside)
        submitSignINButton.frame = CGRect(x: 40, y: view.frame.width - 120 + 50 + 30, width: view.frame.width - 80, height: 40)
        submitSignINButton.tintColor = .black
        submitSignINButton.layer.cornerRadius = 9.0
        submitSignINButton.layer.borderColor = UIColor.black.cgColor
        submitSignINButton.layer.borderWidth = 2.0
        
        emailTextFieldView.addSubview(emailTextField)
        passwordTextFieldView.addSubview(passwordTextField)
        
        view.addSubview(emailTextFieldView)
        view.addSubview(passwordTextFieldView)
        view.addSubview(submitSignINButton)
    }
    
    @objc func submitSignINButtonAction(){
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
                        strongSelf.navigationController?.pushViewController(listChatView, animated: true)
                    }
                }
            }
        }
    }

}

extension EmailSignINViewController:UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
}

