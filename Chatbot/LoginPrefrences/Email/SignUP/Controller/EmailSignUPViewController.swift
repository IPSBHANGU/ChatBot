//
//  EmailSignUPViewController.swift
//  Chatbot
//
//  Created by Umang Kedan on 20/03/24.
//

import UIKit
import FirebaseAuth

class EmailSignUPViewController: UIViewController {
    
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var fullNameTextField: UITextField!
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var profilePhotoImageView: UIImageView!
    @IBOutlet var selectPhotoLabel: UILabel!
    @IBOutlet var submitButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
      setupProfilePhotoPicker()
    }

    func setupProfilePhotoPicker(){
        // Add tap gesture recognizer to profile photo image view
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profilePhotoTapped))
        selectPhotoLabel.isUserInteractionEnabled = true
        selectPhotoLabel.addGestureRecognizer(tapGesture)
    }
    
    @objc func profilePhotoTapped() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @IBAction func submitButtonAction(_ sender: Any) {
        
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
    
    @IBAction func backButtonAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
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
