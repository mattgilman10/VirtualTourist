//
//  Map+Extensions.swift
//  Virtual Tourist
//
//  Created by Matthew Gilman on 3/19/19.
//  Copyright © 2019 Matt Gilman. All rights reserved.
//

import Foundation
import CoreData
import MapKit

@objc(Pin)
extension Pin: MKAnnotation {
    
    public var coordinate: CLLocationCoordinate2D {
        // latitude and longitude are optional NSNumbers        
        let latDegrees = CLLocationDegrees(lat)
        let longDegrees = CLLocationDegrees(lon)
        return CLLocationCoordinate2D(latitude: latDegrees, longitude: longDegrees)
    }
}

