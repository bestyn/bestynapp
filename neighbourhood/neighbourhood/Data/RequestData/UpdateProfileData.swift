//
//  UpdateProfileData.swift
//  neighbourhood
//
//  Created by Dioksa on 25.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

struct UpdateProfileData: Codable {
    var fullName: String? = nil
    var address: String? = nil
    var publicAddress: String? = nil
    var placeId: String? = nil
    var gender: UserGenderType? = nil
    var longitude: Float? = nil
    var latitude: Float? = nil
    var birthday: Date? = nil
    var seeBusinessPosts: Bool
    
    private enum CodingKeys: String, CodingKey {
        case fullName, address, gender, longitude, latitude, placeId
        case birthday, seeBusinessPosts, publicAddress
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let fullName = fullName {
            try container.encode(fullName, forKey: .fullName)
        }
        if let address = address {
            try container.encode(address, forKey: .address)
        }
        if let placeId = placeId {
            try container.encode(placeId, forKey: .placeId)
        }
        if let gender = gender {
            try container.encode(gender, forKey: .gender)
        }
        if let longitude = longitude {
            try container.encode(longitude, forKey: .longitude)
        }
        if let latitude = latitude {
            try container.encode(latitude, forKey: .latitude)
        }

        if let birthday = birthday {
            try container.encode(Int(birthday.timeIntervalSince1970), forKey: .birthday)
        }
        if let publicAddress = publicAddress {
            try container.encode(publicAddress, forKey: .publicAddress)
        }
        try container.encode(seeBusinessPosts == true ? 1 : 0, forKey: .seeBusinessPosts)
    }
}
