//
//  GroupDetailsCell.swift
//  Chatbot
//
//  Created by Umang Kedan on 05/04/24.
//

import UIKit

class GroupDetailsCell: UITableViewCell {
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var profileAvatar: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func setCellData(name: String?, image: UIImage?){
        nameLabel.text = name ?? ""
        profileAvatar.image = image
    }
    
}
