//
//  GroupDetailsCell.swift
//  Chatbot
//
//  Created by Umang Kedan on 05/04/24.
//

import UIKit
import Kingfisher

class GroupDetailsCell: UITableViewCell {
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var profileAvatar: UIImageView!
    @IBOutlet weak var groupAdminLable: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func setCellData(name: String?, image: String?, isGroupAdmin:Bool = false){
        nameLabel.text = name ?? ""
        nameLabel.font = UIFont(name: "Rubik-Regular", size: 18)
        profileAvatar.kf.setImage(with: URL(string: image ?? ""))
        profileAvatar.clipsToBounds = true
        profileAvatar.layer.cornerRadius = 15
        groupAdminLable.layer.cornerRadius = 2
        groupAdminLable.layer.masksToBounds = true
        groupAdminLable.textAlignment = .center
        groupAdminLable.font = UIFont(name: "Rubik-SemiBold", size: 12)
        groupAdminLable.isHidden = !isGroupAdmin
    }
    
}
