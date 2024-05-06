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
    
    // MARK: UIData
    var imageURL:URL?
    var message:String?
    
    var startFrame: CGRect?
    var endFrame: CGRect?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        UIView.animate(withDuration: 0.30, animations: {
            self.imageView.transform = .identity
        })
    }

    func setupView(){
        imageView.kf.setImage(with: imageURL)
        messageLabel.font = UIFont(name: "Rubik-Regular", size: 15)
        messageLabel.text = message
        messageLabel.textColor = .white
        messageLabel.textAlignment = .center
        imageView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
    }

    @IBAction func backButtonAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}
