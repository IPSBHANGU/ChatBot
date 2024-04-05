//
//  GroupDetailsController.swift
//  Chatbot
//
//  Created by Umang Kedan on 05/04/24.
//

import UIKit

class GroupDetailsController: UIViewController {
    
    @IBOutlet var memberTableView: UITableView!
    @IBOutlet var adminNameLabel: UILabel!
    @IBOutlet var profileImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        memberTableView.delegate = self
        memberTableView.dataSource = self
        
    }
}

extension GroupDetailsController : UITableViewDelegate , UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        <#code#>
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        <#code#>
    }
    
    
}
