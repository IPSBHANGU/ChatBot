//
//  ListChatTableViewCell.swift
//  Chatbot
//
//  Created by Inderpreet Singh on 19/03/24.
//

import UIKit

class ListChatTableViewCell: UITableViewCell {

    let userAvatar = UIImageView()
    let userNameLabel = UILabel()
    let userSummery = UILabel()
    let timeLabel = UILabel()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupUI()
    }
    
    func setupUI() {
        userAvatar.contentMode = .scaleAspectFit
        userAvatar.clipsToBounds = true
        userAvatar.layer.cornerRadius = 20
        contentView.addSubview(userAvatar)
        
        userNameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        userSummery.font = UIFont.systemFont(ofSize: 12)
        userSummery.textColor = .placeholderText
        contentView.addSubview(userNameLabel)
        contentView.addSubview(userSummery)
        
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.textColor = .gray
        timeLabel.textAlignment = .right
        contentView.addSubview(timeLabel)
        
        let avatarSize: CGFloat = 40
        let cellWidth = contentView.bounds.width
        
        userAvatar.frame = CGRect(x: 16, y: 10, width: avatarSize, height: avatarSize)
        userNameLabel.frame = CGRect(x: userAvatar.frame.maxX + 16, y: userAvatar.frame.midY - 20, width: cellWidth - userAvatar.frame.maxX - 32, height: 20)
        userSummery.frame = CGRect(x: userAvatar.frame.maxX + 16, y: userAvatar.frame.midY - 5, width: cellWidth - userAvatar.frame.maxX - 32, height: 20)
        
        timeLabel.frame = CGRect(x: cellWidth - 40, y: userAvatar.frame.midY - 10, width: 84, height: 20)
    }


    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setCellData(userImage:UIImage?, username:String?, userRecentMeassage:String?, meassageTime:String?){
        if let userImage = userImage {
            userAvatar.image = userImage
        } else {
            userAvatar.image = UIImage(systemName: "person")
            userAvatar.tintColor = .black
        }
        userNameLabel.text = username ?? ""
        userSummery.text = userRecentMeassage ?? ""
        timeLabel.text = meassageTime ?? ""
    }
    
}
