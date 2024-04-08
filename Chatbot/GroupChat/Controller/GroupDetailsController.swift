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
    @IBOutlet weak var membersLable: UILabel!
    @IBOutlet var memberTableView: UITableView!
    @IBOutlet var profileImageView: UIImageView!
    
    var admin : String?
    var groupName : String?
    var groupAvtar : String?
    var members : [String] = []
    var membersDetails:[[String:Any]]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fixUI()
        fetchUsers()
        setupTableView()
        setGroupAdmin()
        setupGroupDetails()
    }
    
    @IBAction func backButtonAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func fixUI(){
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 75
        membersLable.font = UIFont(name: "Rubik-SemiBold", size: 20)
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
        }
    }
    
    func setupTableView(){
        memberTableView.delegate = self
        memberTableView.dataSource = self
        memberTableView.separatorStyle = .none
        memberTableView.register(UINib(nibName: "GroupDetailsCell", bundle: .main), forCellReuseIdentifier: "groupCell")
    }
    
    func setGroupAdmin(){
        LoginModel().fetchUserDetails(userID: admin ?? "") { user, error in
            if let error = error {
                AlerUser().alertUser(viewController: self, title: "Error", message: error.localizedDescription)
            }
            
            let adminUserDetailsDict: [String: Any] = [
                "displayName": user?.displayName ?? "",
                "email": user?.email ?? "",
                "photoURL": user?.photoURL ?? "",
                "uid": user?.uid ?? "",
            ]
            
            self.membersDetails?.insert(adminUserDetailsDict, at: 0)
            self.memberTableView.reloadData()
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
            let userUID = user["uid"] as? String ?? ""
            
            if userUID == admin {
                cell.setCellData(name: username, image: avtarURL, isGroupAdmin: true)
            } else {
                cell.setCellData(name: username , image: avtarURL)
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
