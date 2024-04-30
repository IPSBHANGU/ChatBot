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
    @IBOutlet weak var messageTime: UILabel!
    @IBOutlet weak var messageStatusLabel: UILabel!
    @IBOutlet weak var messageSeparatorDotView: UIView!
    @IBOutlet weak var receiverAvatarView: UIImageView!
    @IBOutlet weak var senderAvatarView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
