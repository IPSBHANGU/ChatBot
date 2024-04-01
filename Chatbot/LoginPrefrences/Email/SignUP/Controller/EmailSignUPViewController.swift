//
//  EmailSignUPViewController.swift
//  Chatbot
//
//  Created by Umang Kedan on 20/03/24.
//

import UIKit
import FirebaseAuth

class EmailSignUPViewController: UIViewController {

    lazy var emailTextFieldView = UIView()
    lazy var emailTextField = UITextField()
    lazy var passwordTextFieldView = UIView()
    lazy var passwordTextField = UITextField()
    lazy var profilePhotoImageView = UIImageView()
    lazy var fullNameTextFieldView = UIView()
    lazy var fullNameTextField = UITextField()
    lazy var submitSignUPButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupUI()
        setupProfilePhotoPicker()
    }

    func setupUI(){
        emailTextField.placeholder = "Email Address"
        passwordTextField.placeholder = "Password"
        fullNameTextField.placeholder = "Full Name"
        profilePhotoImageView.image = UIImage(systemName: "person")
        
        // Set frames for UI elements
        let profilePhotoSize: CGFloat = 100
        profilePhotoImageView.frame = CGRect(x: (view.frame.width - profilePhotoSize) / 2, y: 100, width: profilePhotoSize, height: profilePhotoSize)
        
        fullNameTextFieldView.frame = CGRect(x: 24, y: profilePhotoImageView.frame.maxY + 20, width: view.frame.width - 48, height: 40)
        fullNameTextField.frame = CGRect(x: 2, y: 0, width: fullNameTextFieldView.frame.width, height: fullNameTextFieldView.frame.height)
        
        emailTextFieldView.frame = CGRect(x: 24, y: fullNameTextFieldView.frame.maxY + 20, width: view.frame.width - 48, height: 40)
        emailTextField.frame = CGRect(x: 2, y: 0, width: emailTextFieldView.frame.width, height: emailTextFieldView.frame.height)
        
        passwordTextFieldView.frame = CGRect(x: 24, y: emailTextFieldView.frame.maxY + 20, width: view.frame.width - 48, height: 40)
        passwordTextField.frame = CGRect(x: 2, y: 0, width: passwordTextFieldView.frame.width, height: passwordTextFieldView.frame.height)
        
        // Customize UI elements
        profilePhotoImageView.layer.cornerRadius = profilePhotoImageView.frame.width / 2
        profilePhotoImageView.layer.borderColor = UIColor.black.cgColor
        profilePhotoImageView.layer.borderWidth = 2.0
        profilePhotoImageView.clipsToBounds = true
        
        fullNameTextField.tintColor = .black
        fullNameTextFieldView.layer.cornerRadius = 9.0
        fullNameTextFieldView.layer.borderColor = UIColor.black.cgColor
        fullNameTextFieldView.layer.borderWidth = 2.0
        fullNameTextFieldView.addSubview(fullNameTextField)
        
        emailTextField.tintColor = .black
        emailTextFieldView.layer.cornerRadius = 9.0
        emailTextFieldView.layer.borderColor = UIColor.black.cgColor
        emailTextFieldView.layer.borderWidth = 2.0
        emailTextFieldView.addSubview(emailTextField)
        
        passwordTextField.tintColor = .black
        passwordTextField.isSecureTextEntry = true
        passwordTextFieldView.layer.cornerRadius = 9.0
        passwordTextFieldView.layer.borderColor = UIColor.black.cgColor
        passwordTextFieldView.layer.borderWidth = 2.0
        passwordTextFieldView.addSubview(passwordTextField)
        
        // Add subviews
        view.addSubview(profilePhotoImageView)
        view.addSubview(fullNameTextFieldView)
        view.addSubview(emailTextFieldView)
        view.addSubview(passwordTextFieldView)
        
        // Add submit button
        submitSignUPButton.setTitle("Submit", for: .normal)
        submitSignUPButton.addTarget(self, action: #selector(submitSignUPButtonAction), for: .touchUpInside)
        submitSignUPButton.frame = CGRect(x: 40, y: passwordTextFieldView.frame.maxY + 20, width: view.frame.width - 80, height: 40)
        submitSignUPButton.tintColor = .black
        submitSignUPButton.layer.cornerRadius = 9.0
        submitSignUPButton.layer.borderColor = UIColor.black.cgColor
        submitSignUPButton.layer.borderWidth = 2.0
        view.addSubview(submitSignUPButton)
    }
    
    func setupProfilePhotoPicker(){
        // Add tap gesture recognizer to profile photo image view
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profilePhotoTapped))
        profilePhotoImageView.isUserInteractionEnabled = true
        profilePhotoImageView.addGestureRecognizer(tapGesture)
    }
    
    @objc func profilePhotoTapped() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @objc func submitSignUPButtonAction(){
        Auth.auth().createUser(withEmail: emailTextField.text ?? "", password: passwordTextField.text ?? "") { result, error in
            if let error = error {
                AlerUser().alertUser(viewController: self, title: "Error", message: error.localizedDescription)
            } else {
                LoginModel().uploadUserAvtar(userAvtar: self.profilePhotoImageView.image, currentUser: result?.user) { status in
                    switch status {
                    case .failure(let error):
                        AlerUser().alertUser(viewController: self, title: "Error", message: "Error uploading avatar: \(error.localizedDescription)")
                    case .success(_):
                        LoginModel().downloadUserAvtarURL(currentUser: result?.user) { is_Success, url in
                            if let error = error {
                                AlerUser().alertUser(viewController: self, title: "Error", message: error.localizedDescription)
                                return
                            }
                            if is_Success == true {
                                LoginModel().addUsersToDb(user: result?.user, displayName: self.fullNameTextField.text ?? "", photoURL: url) { isSucceeded, error in
                                    if let error = error {
                                        AlerUser().alertUser(viewController: self, title: "Error", message: error)
                                        return
                                    } else if isSucceeded {
                                        /*
                                         * At this point User is Authenticated
                                         * move to next View
                                         */
                                        let listChatView = ListChatViewController()
                                        // pass whole result
                                        listChatView.result = result
                                        self.navigationController?.pushViewController(listChatView, animated: true)
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

extension EmailSignUPViewController:UITextFieldDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            profilePhotoImageView.image = selectedImage
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
}
