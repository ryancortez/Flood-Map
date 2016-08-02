//
//  FloodingLocation.swift
//  Flood Map
//
//  Created by Ryan Cortez on 8/2/16.
//  Copyright © 2016 Ryan Cortez. All rights reserved.
//

import CloudKit
import CoreLocation

class FloodingLocation: NSObject {
    var location: CLLocation!
    var cloudKitRecordID: CKRecordID!
    
    init(withLocation location: CLLocation, andCloudKitRecordID cloudKitRecordID: CKRecordID) {
        self.location = location
        self.cloudKitRecordID = cloudKitRecordID
    }
}
