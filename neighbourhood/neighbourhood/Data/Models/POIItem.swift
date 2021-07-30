//
//  POIItem.swift
//  neighbourhood
//
//  Created by Dioksa on 16.06.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import GoogleMaps
import GooglePlaces
import GoogleMapsUtils

final class POIItem: NSObject, GMUClusterItem {
    var position: CLLocationCoordinate2D
    let id: Int
    let type: ProfileType
    let avatar: URL?
    let fullName: String
    let isBusiness: Bool
    
    init(position: CLLocationCoordinate2D, id: Int, type: ProfileType, avatar: URL?, fullName: String, isBusiness: Bool = false) {
        self.position = position
        self.id = id
        self.type = type
        self.avatar = avatar
        self.fullName = fullName
        self.isBusiness = isBusiness
    }
}
