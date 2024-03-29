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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setCellData(userImage:String?, username:String?, userRecentMeassage:String?, meassageTime:String?) {
        if let userImage = userImage {
            profileImageView.kf.setImage(with: URL(string: userImage))
        } else {
            profileImageView.image = UIImage(systemName: "person")
            profileImageView.tintColor = .black
        }
        nameLabel.text = username ?? ""
        nameLabel.font = UIFont(name: "Rubik-SemiBold", size: 15)
        nameLabel.textColor = UIColorHex().hexStringToUIColor(hex: "#191919")
        messageLabel.text = userRecentMeassage ?? ""
        messageLabel.font = UIFont(name: "Rubik-Regular", size: 14)
        messageLabel.textColor = UIColorHex().hexStringToUIColor(hex: "#A2A2A2")
        timingLabel.text = meassageTime ?? ""
        timingLabel.font = UIFont(name: "Rubik-Regular", size: 13)
        timingLabel.textColor = UIColorHex().hexStringToUIColor(hex: "#A2A2A2")
    }
    
}
