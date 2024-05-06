//
//  ImageViewTableViewCell.swift
//  Chatbot
//
//  Created by Inderpreet Singh on 29/04/24.
//

import UIKit
import Kingfisher

class ImageViewTableViewCell: UITableViewCell {
    
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var imageMessageView: ImageMessageHandler!
    @IBOutlet weak var messageTime: UILabel!
    @IBOutlet weak var messageStatusLabel: UILabel!
    @IBOutlet weak var messageSeparatorDotView: UIView!
    @IBOutlet weak var receiverAvatarView: UIImageView!
    @IBOutlet weak var senderAvatarView: UIImageView!
    @IBOutlet weak var messageLable: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setCellData(image:URL, message: String?, messageStatus:String?, senderAvtar:String?, isCurrentUser: Bool, messageReadStatus:Bool = true) {
        bubbleView.layer.cornerRadius = 20
        messageTime.text = messageStatus ?? ""
        messageLable.font = UIFont(name: "Rubik-Regular", size: 14)
        messageLable.text = message
        
        // Calculate the appropriate width based on the text content
        let labelSize = self.messageLable.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: 40))
        self.messageLable.frame.size.width = labelSize.width

        if isCurrentUser {
            let cornerMask:CACornerMask = [.layerMinXMinYCorner, .layerMaxXMaxYCorner , .layerMinXMaxYCorner ]
            bubbleView.layer.maskedCorners = cornerMask
            bubbleView.clipsToBounds = true
            senderAvatarView?.isHidden = false
            receiverAvatarView?.isHidden = true
            bubbleView.backgroundColor = UIColorHex().hexStringToUIColor(hex: "#3780C2")
            imageMessageView.prepareForMessageView(imageURL: image)
            messageLable.textColor = .white
            messageTime.textColor = UIColorHex().hexStringToUIColor(hex: "#9BBFE0")
            messageSeparatorDotView.isHidden = false
            if messageReadStatus == true {
                messageStatusLabel.text = "Read"
            }
            messageStatusLabel.isHidden = false
            messageStatusLabel.textColor = .white
            if let avatarURL = URL(string: senderAvtar ?? "") {
                senderAvatarView.kf.setImage(with: avatarURL, placeholder: UIImage(systemName: "person.circle"))
            } else {
                senderAvatarView.image = UIImage(systemName: "person.circle")
            }
            senderAvatarView.layer.cornerRadius = 16
        }
        else
        {
            let cornerMask:CACornerMask = [ .layerMaxXMinYCorner , .layerMaxXMaxYCorner , .layerMinXMaxYCorner ]
            bubbleView.layer.maskedCorners = cornerMask
            bubbleView.clipsToBounds = true
            receiverAvatarView?.isHidden = false
            senderAvatarView?.isHidden = true
            bubbleView.backgroundColor = UIColorHex().hexStringToUIColor(hex: "#F4F4F4")
            imageMessageView.prepareForMessageView(imageURL: image)
            messageLable.textColor = .black
            messageTime.textColor = UIColorHex().hexStringToUIColor(hex: "#A2A2A2")
            
            // messageStatus should not be visible for recieved meassages
            messageSeparatorDotView.isHidden = true
            messageStatusLabel.isHidden = true
            if let avatarURL = URL(string: senderAvtar ?? "") {
                receiverAvatarView.kf.setImage(with: avatarURL, placeholder: UIImage(systemName: "person.circle"))
            } else {
                receiverAvatarView.image = UIImage(systemName: "person.circle")
            }
            receiverAvatarView.layer.cornerRadius = 16
        }
    }
}
