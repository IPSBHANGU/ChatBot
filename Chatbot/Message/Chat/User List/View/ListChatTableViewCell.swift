//
//  ListChatTableViewCell.swift
//  Chatbot
//
//  Created by Inderpreet Singh on 19/03/24.
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
        messageLabel.text = userRecentMeassage ?? ""
        timingLabel.text = meassageTime ?? ""
    }
    
}
