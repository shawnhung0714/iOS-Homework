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

    var store = AirportStore()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                guard let country = store.countries?[indexPath.section] else {
                    return
                }
                guard let airports = store.airportsIn(country: country) else {
                    return
                }
                let detail = segue.destination as! DetailViewController
                detail.airport = airports[indexPath.row]
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return store.countries?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let country = store.countries?[section] else {
            return nil
        }

        return country
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let country = store.countries?[section] else {
            return 0
        }
        guard let airports = store.airportsIn(country: country) else {
            return 0
        }

        return airports.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        guard let country = store.countries?[indexPath.section] else {
            return cell
        }
        guard let airports = store.airportsIn(country: country) else {
            return cell
        }

        let airport = airports[indexPath.row]
        cell.textLabel?.text = airport.name
        cell.detailTextLabel?.text = airport.iata
        let label = cell.viewWithTag(12345) as! UILabel
        label.text = airport.city
        return cell
    }
}

