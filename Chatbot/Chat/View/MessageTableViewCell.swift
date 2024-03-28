//
//  MessageTableViewCell.swift
//  Chatbot
//
//  Created by Inderpreet Singh on 26/03/24.
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
        if isCurrentUser {
            bubbleView.backgroundColor = UIColorHex().hexStringToUIColor(hex: "#3780C2")
            messageLable.textColor = .white
            messageTime.textColor = .lightText
            messageStatusLable.textColor = .lightText
            bubbleViewTrailing = bubbleViewTrailing.setRelation(relation: .equal, constant: 60)
            bubbleViewLeading = bubbleViewLeading.setRelation(relation: .greaterThanOrEqual, constant: 80)
            recieverAvtarView.removeFromSuperview()
            senderAvtarView.kf.setImage(with: URL(string: senderAvtar ?? ""))
            senderAvtarView.layer.cornerRadius = 16.5
        } else {
            bubbleView.backgroundColor = UIColorHex().hexStringToUIColor(hex: "#F4F4F4")
            messageLable.textColor = .black
            messageTime.textColor = .placeholderText
            messageStatusLable.textColor = .placeholderText
            bubbleViewLeading = bubbleViewLeading.setRelation(relation: .equal, constant: 60)
            bubbleViewTrailing = bubbleViewTrailing.setRelation(relation: .greaterThanOrEqual, constant: 80)
            senderAvtarView.removeFromSuperview()
            recieverAvtarView.kf.setImage(with: URL(string: senderAvtar ?? ""))
            recieverAvtarView.layer.cornerRadius = 16.5
        }
    }
}
