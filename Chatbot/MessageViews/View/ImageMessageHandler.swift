//
//  ImageMessageHandler.swift
//  testing
//
//  Created by Inderpreet Singh on 30/04/24.
//

import UIKit
import GrowingTextView
import Kingfisher

protocol ImageMessageDelegate: AnyObject {
    func callForViewDisplay(displayView:Bool)
    
    func sendButtonCallBack(image:UIImage, message:String)
}

class ImageMessageHandler:UIView {
    
    // MARK: UIElements
    lazy var closeButton = UIButton(type: .close)
    lazy var imageView = UIImageView()
    lazy var messageTextView = GrowingTextView()
    lazy var sendButton = UIButton(type: .system)
    lazy var recieverLable = UILabel()
    
    // MARK: Pass Data to Controller
    weak var delegate: ImageMessageDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    func setupUI(){
        self.backgroundColor = .systemGray6
        
        closeButton.frame = CGRect(x: 20, y: 10, width: 50, height: 50)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(closeButtonAction), for: .touchUpInside)
        addSubview(closeButton)
        
        imageView.frame = CGRect(x: 20, y: 100, width: 300, height: 300)
        imageView.contentMode = .scaleAspectFill
        addSubview(imageView)
        
        messageTextView.frame = CGRect(x: imageView.frame.origin.x, y: imageView.frame.maxY + 80, width: imageView.frame.width - 40, height: 50)
        messageTextView.backgroundColor = .white
        messageTextView.layer.cornerRadius = 15
        messageTextView.placeholder = "Message...."
        addSubview(messageTextView)
        
        sendButton.frame = CGRect(x: messageTextView.frame.width + 30, y: messageTextView.frame.origin.y, width: 50, height: 50)
        sendButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        sendButton.backgroundColor = UIColorHex().hexStringToUIColor(hex: "E2DEF8")
        sendButton.layer.cornerRadius = sendButton.frame.width / 2
        sendButton.tintColor = UIColorHex().hexStringToUIColor(hex: "683BD8")
        sendButton.addTarget(self, action: #selector(sendButtonAction), for: .touchUpInside)
        addSubview(sendButton)
    }
    
    func prepareForMessageView(imageURL: URL){
        closeButton.alpha = 0
        sendButton.alpha = 0
        self.backgroundColor = .clear
        imageView.frame = CGRect(x: 6, y: 6, width: frame.width - 12, height: frame.height)
        imageView.layer.masksToBounds = true
        let placeholderImage = UIImage(systemName: "network")
        imageView.kf.setImage(
            with: imageURL,
            placeholder: placeholderImage,
            options: nil,
            progressBlock: nil,
            completionHandler: nil
        )
        imageView.contentMode = .scaleToFill
    }
    
    func setupPickerView(from viewController: UIViewController){
        let imagePicker = GetImageFromPicker()
        imagePicker.imagePicker?.delegate = self
        imagePicker.setImagePicker(imagePickerType: .both, controller: viewController)
    }
    
    func setupRecipientLable(recipient: String){
        DispatchQueue.main.async {
            
            self.recieverLable.frame = CGRect(x: self.messageTextView.frame.origin.x, y: self.messageTextView.frame.origin.y + 50 + 20, width: 100, height: 30)
            self.recieverLable.text = " \(recipient) "
            self.recieverLable.layer.cornerRadius = 5.0
            self.recieverLable.layer.masksToBounds = true
            self.recieverLable.backgroundColor = .systemGray3
            self.recieverLable.textColor = UIColor.white
            
            // Calculate the appropriate width based on the text content
            let labelSize = self.recieverLable.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: 40))
            self.recieverLable.frame.size.width = labelSize.width
        }
        addSubview(recieverLable)
    }
    
    @objc func closeButtonAction(){
        delegate?.callForViewDisplay(displayView: false)
    }
    
    @objc func sendButtonAction() {
        delegate?.sendButtonCallBack(image: imageView.image!, message: messageTextView.text ?? "")
    }
}

extension ImageMessageHandler: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.originalImage] as? UIImage {
            delegate?.callForViewDisplay(displayView: true)
            imageView.image = selectedImage
        }
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
