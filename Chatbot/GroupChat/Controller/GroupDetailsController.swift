//
//  GroupDetailsController.swift
//  Chatbot
//
//  Created by Umang Kedan on 05/04/24.
//

import UIKit
import Kingfisher

class GroupDetailsController: UIViewController {
    
    @IBOutlet var groupNameLabel: UILabel!
    @IBOutlet var memberTableView: UITableView!
    @IBOutlet var adminNameLabel: UILabel!
    @IBOutlet var profileImageView: UIImageView!
    
    var admin : String?
    var groupName : String?
    var groupAvtar : String?
    var members : [String] = []
    var membersDetails:[[String:Any]]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchUsers()
        setupTableView()
        setGroupAdmin()
        setupGroupDetails()
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func setupGroupDetails(){
        groupNameLabel.text = groupName
        profileImageView.kf.setImage(with: URL(string: groupAvtar ?? ""))
    }
    
    func fetchUsers(){
        GroupModel().fetchGroupUsersDetails(members: members) { users, error in
            if let error = error {
                AlerUser().alertUser(viewController: self, title: "Error", message: error)
                return
            }
            self.membersDetails = users
            self.memberTableView.reloadData()
        }
    }
    
    func setupTableView(){
        memberTableView.delegate = self
        memberTableView.dataSource = self
        memberTableView.register(UINib(nibName: "GroupDetailsCell", bundle: .main), forCellReuseIdentifier: "groupCell")
    }
    
    func setGroupAdmin(){
        LoginModel().fetchUserDetails(userID: admin ?? "") { user, error in
            if let error = error {
                AlerUser().alertUser(viewController: self, title: "Error", message: error.localizedDescription)
            }
            
            self.adminNameLabel.text = user?.displayName ?? ""

            /**
             CHANGE WHEN YOU HAVE UIIMAGEVIEW
             UIIMAGEVIEW.kf.setImage(with: URL(string: user?.photoURL ?? ""))
             */
        }
    }
}

extension GroupDetailsController : UITableViewDelegate , UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return membersDetails?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "groupCell") as? GroupDetailsCell else {
            return UITableViewCell()
        }
        if let groupUserArray = membersDetails, indexPath.row < membersDetails?.count ?? 0 {
            let user = groupUserArray[indexPath.row]
            let username = user["displayName"] as? String ?? ""
            let avtarURL = user["photoURL"] as? String ?? ""
            cell.setCellData(name: username , image: avtarURL)
        }
        return cell
    }
}
