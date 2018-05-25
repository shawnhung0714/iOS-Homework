//
//  HistoryViewController.swift
//  ARBasketBall
//
//  Created by Shawn Hung on 2018/5/26.
//  Copyright © 2018 Shawn Hung. All rights reserved.
//

import UIKit
import FirebaseDatabase

class HistoryViewController: UITableViewController {

    var dbRef: DatabaseReference!
    var scores: [Int]?
    override func viewDidLoad() {
        super.viewDidLoad()
        let backBarButton = UIBarButtonItem(title: "< back", style: .plain, target: self, action: #selector(back))
        
        navigationItem.leftBarButtonItem = backBarButton
        
        dbRef = Database.database().reference()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        dbRef.child("History").observe(.value) { (snapshot) in
            self.scores = snapshot.value as? [Int]
            self.tableView.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return scores?.count ?? 0
    }
    
    @objc func back() {
        navigationController?.popViewController(animated: true)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell", for: indexPath)
        guard let aScores = scores else {
            return cell
        }
        cell.textLabel?.text = "\(aScores[indexPath.row])"
        return cell
    }
}
