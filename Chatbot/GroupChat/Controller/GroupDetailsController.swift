//
//  GroupDetailsController.swift
//  Chatbot
//
//  Created by Umang Kedan on 05/04/24.
//

import UIKit

class GroupDetailsController: UIViewController {
    
    @IBOutlet var groupNameLabel: UILabel!
    @IBOutlet var memberTableView: UITableView!
    @IBOutlet var adminNameLabel: UILabel!
    @IBOutlet var profileImageView: UIImageView!
    
    var admin : String?
    var groupName : String?
    var members : [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        memberTableView.delegate = self
        memberTableView.dataSource = self
        adminNameLabel.text = admin
        groupNameLabel.text = groupName
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension GroupDetailsController : UITableViewDelegate , UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return members.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let user = members[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "groupCell") as? GroupDetailsCell else {
            return UITableViewCell()
        }
        cell.setCellData(name: user , image: UIImage(systemName: "person"))
        return cell
    }
}
