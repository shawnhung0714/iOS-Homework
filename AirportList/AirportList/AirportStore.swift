//
//  AirportStore.swift
//  AirportList
//
//  Created by Shawn Hung on 2018/4/30.
//  Copyright © 2018 Shawn Hung. All rights reserved.
//

import UIKit

class AirportStore: NSObject {
    var airportGroups: [String: [Airport]]? = nil

    public var countries: [String]? {
        get{
            return airportGroups?.keys.sorted()
        }
    }

    override init() {
        if let url = Bundle.main.url(forResource: "airports", withExtension: "plist") {
            let entries = NSArray(contentsOf: url)
            let airports: [Airport]? = entries?.map({(dict:Any) in
                Airport(fromDict:dict as! Dictionary<String, String>)
            })

            if let airportList = airports {
                airportGroups = Dictionary(grouping: airportList, by: {$0.country!})
            }
        }
    }

    public func airportsIn(country:String) -> [Airport]? {
        return airportGroups?[country]
    }
}
