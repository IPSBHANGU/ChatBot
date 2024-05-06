//
//  ImageMessageExpandViewController.swift
//  Chatbot
//
//  Created by Inderpreet Singh on 03/05/24.
//

import UIKit
import Kingfisher

class ImageMessageExpandViewController: UIViewController {

    // MARK: UIElements
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var backgroundView: UIView!
    
    // MARK: UIData
    var imageURL:URL?
    var message:String?
    
    var startFrame: CGRect?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        backgroundView.alpha = 0
        UIView.animate(withDuration: 0.30) {
            self.imageView.transform = .identity
            UIView.animate(withDuration: 0.30) {
                self.backgroundView.alpha = 1
            }
        }
    }

    func setupView(){
        imageView.kf.setImage(with: imageURL)
        messageLabel.font = UIFont(name: "Rubik-Regular", size: 15)
        messageLabel.text = message
        messageLabel.textColor = .white
        messageLabel.textAlignment = .center
        
        guard let startFrame = startFrame else {return}
        imageView.transform = CGAffineTransform(from: imageView.frame, to: startFrame)
    }

    @IBAction func backButtonAction(_ sender: Any) {
        guard let startFrame = startFrame else {return}
        UIView.animate(withDuration: 0.30) {
            self.imageView.transform = CGAffineTransform(from: self.imageView.frame, to: startFrame)
            self.backgroundView.alpha = 0
            self.backButton.alpha = 0
            self.imageView.alpha = 0
            self.messageLabel.alpha = 0
        } completion: { _ in
            self.dismiss(animated: false, completion: nil)
        }
    }
    
}

