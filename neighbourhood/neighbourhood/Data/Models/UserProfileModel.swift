//
//  UserProfile.swift
//  neighbourhood
//
//  Created by Dioksa on 30.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

enum UserGenderType: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
    case other = "Other"
    case notSelected = "Not set"
}

struct ProfileCounters: Codable {
    let followers: Int
    let following: Int
}

struct UserProfileModel: Codable {
    let id: Int
    let type: ProfileType
    let avatar: ImageModel?
    let fullName: String
    let address: String?
    let publicAddress: String?
    let longitude: Float?
    let latitude: Float?
    let placeId: String?
    let gender: UserGenderType?
    let birthday: Date?
    let hashtags: [HashtagModel]
    let createdAt: Date?
    let updatedAt: Date?
    let seeBusinessPosts: Bool
    var hasUnreadMessages: Bool?
    var counters: ProfileCounters?
    
    private enum CodingKeys: String, CodingKey {
        case id, type, avatar, fullName, address, publicAddress, gender, longitude, latitude
        case birthday, createdAt, updatedAt, seeBusinessPosts, hasUnreadMessages, placeId
        case hashtags, counters
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(.id)
        type = try container.decode(.type)
        avatar = try? container.decode(.avatar)
        fullName = try container.decode(.fullName)
        address = try container.decode(.address)
        publicAddress = try? container.decode(.publicAddress)
        placeId = try? container.decode(.placeId)
        gender = try container.decode(.gender)
        hasUnreadMessages = try? container.decode(.hasUnreadMessages)
        longitude = try? container.decode(.longitude)
        latitude = try? container.decode(.latitude)
        
        if let timestamp: Double = try? container.decode(.birthday) {
            birthday = Date(timeIntervalSince1970: timestamp)
        } else {
            birthday = nil
        }

        hashtags = (try? container.decode(.hashtags)) ?? []
        createdAt = try container.decode(.createdAt)
        updatedAt = try container.decode(.updatedAt)

        let seen: Int = try container.decode(.seeBusinessPosts)
        seeBusinessPosts = seen != 0
        counters = try? container.decode(.counters)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(avatar, forKey: .avatar)
        try container.encode(fullName, forKey: .fullName)
        try container.encode(address, forKey: .address)
        try container.encode(publicAddress, forKey: .publicAddress)
        try container.encode(placeId, forKey: .placeId)
        try container.encode(gender, forKey: .gender)
        try container.encode(birthday?.timeIntervalSince1970, forKey: .birthday)
        try container.encode(hashtags, forKey: .hashtags)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(seeBusinessPosts ? 1 : 0, forKey: .seeBusinessPosts)
        try container.encode(hasUnreadMessages, forKey: .hasUnreadMessages)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(counters, forKey: .counters)
    }
    
    var genderString: String? {
        guard let gender = gender else { return nil }
        return gender == .notSelected ? nil : "\(R.string.localizable.genderTitle()): \(gender.rawValue)"
    }

    var followersCount: Int {
        return counters?.followers ?? 0
    }

    var followingCount: Int {
        return counters?.following ?? 0
    }
}


struct UserProfileTypeModel: Codable {
    let type: ProfileType
}
