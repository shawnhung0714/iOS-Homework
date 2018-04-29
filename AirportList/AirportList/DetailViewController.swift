//
//  DetailViewController.swift
//  AirportList
//
//  Created by Shawn Hung on 2018/4/22.
//  Copyright © 2018 Shawn Hung. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    
    public var airport: Airport? = nil

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var countryLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!

    func configureView() {
        if let aAirport = airport {
            title = aAirport.iata
            nameLabel.text = aAirport.name
            countryLabel.text = aAirport.country
            cityLabel.text = aAirport.city
            imageView.image = UIImage(named: aAirport.iata! + ".jpg")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

