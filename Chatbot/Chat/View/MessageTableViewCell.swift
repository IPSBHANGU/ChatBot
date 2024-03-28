//
//  MessageTableViewCell.swift
//  Chatbot
//
//  Created by Inderpreet Singh on 26/03/24.
//

import UIKit

class MessageTableViewCell: UITableViewCell {
    
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var bubbleViewLeading: NSLayoutConstraint!
    @IBOutlet weak var bubbleViewTrailing: NSLayoutConstraint!
    @IBOutlet weak var messageLable: UILabel!
    @IBOutlet weak var messageDetails: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setCellData(message: String?, messageStatus:String?, isCurrentUser: Bool) {
        messageLable.numberOfLines = 0
        bubbleView.layer.cornerRadius = 20
        messageLable.text = message ?? ""
        messageDetails.text = messageStatus ?? ""
        if isCurrentUser {
            bubbleView.backgroundColor = UIColorHex().hexStringToUIColor(hex: "#3780C2")
            messageLable.textColor = .white
            messageDetails.textColor = .lightText
            bubbleViewTrailing = bubbleViewTrailing.setRelation(relation: .equal, constant: 10)
            bubbleViewLeading = bubbleViewLeading.setRelation(relation: .greaterThanOrEqual, constant: 80)
        } else {
            bubbleView.backgroundColor = UIColorHex().hexStringToUIColor(hex: "#F4F4F4")
            messageLable.textColor = .black
            messageDetails.textColor = .placeholderText
            bubbleViewLeading = bubbleViewLeading.setRelation(relation: .equal, constant: 10)
            bubbleViewTrailing = bubbleViewTrailing.setRelation(relation: .greaterThanOrEqual, constant: 80)
        }
    }
}
