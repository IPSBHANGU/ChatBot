//
//  ListChatTableViewCell.swift
//  Chatbot
//
//  Created by Umang Kedan on 19/03/24.
//

import UIKit
import Kingfisher

class ListChatTableViewCell: UITableViewCell {

    @IBOutlet var profileImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var timingLabel: UILabel!
    @IBOutlet weak var newMessageStatus: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setCellData(userImage:String?, username:String?, userRecentMeassage:String?, meassageTime:String?, messageReadState:Bool?) {
        profileImageView.kf.setImage(with: URL(string: userImage ?? ""))
        nameLabel.text = username ?? ""
        nameLabel.font = UIFont(name: "Rubik-SemiBold", size: 15)
        nameLabel.textColor = UIColorHex().hexStringToUIColor(hex: "#191919")
        messageLabel.text = userRecentMeassage ?? "Tap to start chat"
        messageLabel.font = UIFont(name: "Rubik-Regular", size: 14)
        messageLabel.textColor = UIColorHex().hexStringToUIColor(hex: "#A2A2A2")
        timingLabel.text = meassageTime ?? ""
        timingLabel.font = UIFont(name: "Rubik-Regular", size: 13)
        if messageReadState == false {
            timingLabel.textColor = .black
            timingLabel.font = UIFont(name: "Rubik-SemiBold", size: 12)
        } else {
            timingLabel.textColor = UIColorHex().hexStringToUIColor(hex: "#A2A2A2")
        }
        newMessageStatus.isHidden = messageReadState ?? true
        newMessageStatus.layer.cornerRadius = 5
    }
    
}
