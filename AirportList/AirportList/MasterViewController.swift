//
//  MasterViewController.swift
//  AirportList
//
//  Created by Shawn Hung on 2018/4/22.
//  Copyright © 2018 Shawn Hung. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController {

    var detailViewController: DetailViewController? = nil
    var airports : [Airport]? = nil


    override func viewDidLoad() {
        super.viewDidLoad()
        if let url = Bundle.main.url(forResource: "airports", withExtension: "plist") {
            let entries = NSArray(contentsOf: url)
            airports = entries?.map({(dict:Any) in
                Airport(fromDict:dict as! Dictionary<String, String>)
            })
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let airport = airports?[indexPath.row]
                let detail = segue.destination as! DetailViewController
                detail.airport = airport
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let airports_unbox = airports {
            return airports_unbox.count
        }
        else {
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let airport = airports?[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = airport?.name
        cell.detailTextLabel?.text = airport?.iata
        let label = cell.viewWithTag(12345) as! UILabel
        label.text = airport?.city
        return cell
    }
}

