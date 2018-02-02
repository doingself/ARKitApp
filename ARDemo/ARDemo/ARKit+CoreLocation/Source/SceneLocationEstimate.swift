//
//  SceneLocationEstimate.swift
//  ARKit+CoreLocation
//
//  Created by Andrew Hart on 03/07/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import Foundation
import CoreLocation
import SceneKit

class SceneLocationEstimate {
    let location: CLLocation
    let position: SCNVector3
    
    init(location: CLLocation, position: SCNVector3) {
        self.location = location
        self.position = position
    }
    
    ///Compares the location's position to another position, to determine the translation between them
    func locationTranslation(to position: SCNVector3) -> LocationTranslation {
        return LocationTranslation(
            latitudeTranslation: Double(self.position.z - position.z),
            longitudeTranslation: Double(position.x - self.position.x),
            altitudeTranslation: Double(position.y - self.position.y))
    }
    
    ///Translates the location by comparing with a given position
    func translatedLocation(to position: SCNVector3) -> CLLocation {
        let translation: LocationTranslation = self.locationTranslation(to: position)
        let translatedLocation = self.location.translatedLocation(with: translation)
        
        return translatedLocation
    }
}
