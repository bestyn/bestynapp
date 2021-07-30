//
//  BusinessProfile.swift
//  neighbourhood
//
//  Created by Dioksa on 13.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import Foundation

enum LocationRadiusVisibility: Codable {
    enum CodingKeys: String, CodingKey {
        case radius
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let newRadius: Int = try container.decode(Int.self)
        if newRadius == 0 { self = .onlyMe}
        else if newRadius == 50 { self = .defaultRadius }
        else {self = .moreMiles(newRadius) }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .onlyMe:
            try container.encode(0)
        case .defaultRadius:
            try container.encode(50)
        case .moreMiles(let radius):
            try container.encode(radius)
        }
    }
    
    case onlyMe
    case defaultRadius
    case moreMiles(_ value: Int)
    
    var value: Int {
        switch self {
        case .onlyMe:
            return 0
        case .defaultRadius:
            return 50
        case .moreMiles(let radius):
            return radius
        }
    }
}

struct BusinessProfile: Codable {
    let id: Int
    let avatar: ImageModel?
    let fullName: String
    let description: String
    let address: String
    let placeId: String?
    let radius: LocationRadiusVisibility
    let site: String?
    let email: String? 
    let phone: String?
    let hashtags: [HashtagModel]
    let createdAt: Date?
    let updatedAt: Date?
    var hasUnreadMessages: Bool?
    let longitude: Float?
    let latitude: Float?
    var isFollowed: Bool
    var isFollower: Bool
    var counters: ProfileCounters?


    enum CodingKeys: String, CodingKey {
        case id, avatar, fullName, description, address, placeId, radius, site, email, phone,
             hashtags, createdAt, updatedAt, hasUnreadMessages, longitude, latitude, isFollowed, isFollower
        case counters
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(.id)
        avatar = try? container.decode(.avatar)
        fullName = try container.decode(.fullName)
        description = try container.decode(.description)
        address = try container.decode(.address)
        placeId = try? container.decode(.placeId)
        radius = try container.decode(.radius)
        site = try? container.decode(.site)
        email = try? container.decode(.email)
        phone = try? container.decode(.phone)
        hashtags = try container.decode(.hashtags)
        createdAt = try? container.decode(.createdAt)
        updatedAt = try? container.decode(.updatedAt)
        hasUnreadMessages = try? container.decode(.hasUnreadMessages)
        longitude = try? container.decode(.longitude)
        latitude = try? container.decode(.latitude)
        isFollowed = (try? container.decode(.isFollowed)) ?? false
        isFollower = (try? container.decode(.isFollower)) ?? false
        counters = try? container.decode(.counters)
    }

    var followersCount: Int {
        return counters?.followers ?? 0
    }

    var followingCount: Int {
        return counters?.following ?? 0
    }
}

