//
//  MessageTableViewCell.swift
//  Chatbot
//
//  Created by Umang Kedan on 26/03/24.
//

import UIKit
import Kingfisher

class MessageTableViewCell: UITableViewCell {
    
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var bubbleViewLeading: NSLayoutConstraint!
    @IBOutlet weak var bubbleViewTrailing: NSLayoutConstraint!
    @IBOutlet weak var messageLable: UILabel!
    @IBOutlet weak var messageTime: UILabel!
    @IBOutlet weak var messageStatusLable: UILabel!
    @IBOutlet weak var recieverAvtarView: UIImageView!
    @IBOutlet weak var senderAvtarView: UIImageView!
    @IBOutlet weak var messageSepratorDotView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setCellData(message: String?, messageStatus:String?, senderAvtar:String?, isCurrentUser: Bool) {
        messageLable.numberOfLines = 0
        bubbleView.layer.cornerRadius = 20
        messageLable.text = message ?? ""
        messageTime.text = messageStatus ?? ""
        messageLable.font = UIFont(name: "Rubik Regular", size: 14)
        if isCurrentUser {
            senderAvtarView?.isHidden = false
            recieverAvtarView?.isHidden = true
            bubbleView.backgroundColor = UIColorHex().hexStringToUIColor(hex: "#3780C2")
            messageLable.textColor = .white
            messageTime.textColor = UIColorHex().hexStringToUIColor(hex: "#9BBFE0")
            messageSepratorDotView.isHidden = false
            messageStatusLable.isHidden = false
            messageStatusLable.textColor = .white
            bubbleViewTrailing = bubbleViewTrailing.setRelation(relation: .equal, constant: 60)
            bubbleViewLeading = bubbleViewLeading.setRelation(relation: .greaterThanOrEqual, constant: 80)
            recieverAvtarView.isHidden = true
            senderAvtarView.isHidden = false
            senderAvtarView.kf.setImage(with: URL(string: senderAvtar ?? ""))
            senderAvtarView.layer.cornerRadius = 16.5
        } else {
            recieverAvtarView?.isHidden = false
            senderAvtarView?.isHidden = true
            bubbleView.backgroundColor = UIColorHex().hexStringToUIColor(hex: "#F4F4F4")
            messageLable.textColor = .black
            messageTime.textColor = UIColorHex().hexStringToUIColor(hex: "#A2A2A2")
            // messageStatus should not be visible for recieved meassages
            messageSepratorDotView.isHidden = true
            messageStatusLable.isHidden = true
            bubbleViewLeading = bubbleViewLeading.setRelation(relation: .equal, constant: 60)
            bubbleViewTrailing = bubbleViewTrailing.setRelation(relation: .greaterThanOrEqual, constant: 80)
            senderAvtarView.isHidden = true
            recieverAvtarView.isHidden = false
            recieverAvtarView.kf.setImage(with: URL(string: senderAvtar ?? ""))
            recieverAvtarView.layer.cornerRadius = 16.5
        }
    }
}
