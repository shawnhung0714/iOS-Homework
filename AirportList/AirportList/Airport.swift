//
//  Airport.swift
//  AirportList
//
//  Created by Shawn Hung on 2018/4/22.
//  Copyright © 2018 Shawn Hung. All rights reserved.
//

import UIKit

public class Airport: NSObject {
    public var name: String?
    public var country: String?
    public var iata: String?
    public var city: String?
    public var shortName: String?
    
    init(fromDict dict:Dictionary<String, String>){
        name = dict["Airport"]
        country = dict["Country"]
        iata = dict["IATA"]
        city = dict["ServedCity"]
        shortName = dict["ShortName"]
    }
}
