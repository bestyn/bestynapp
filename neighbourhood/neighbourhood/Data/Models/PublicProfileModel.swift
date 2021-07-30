//
//  PublicViewModel.swift
//  neighbourhood
//
//  Created by Dioksa on 22.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

struct PublicProfileModel: Codable {
    let id: Int
    let avatar: ImageModel?
    let fullName: String
    let address: String?
    let gender: UserGenderType?
    let birthday: Date?
    let hashtags: [HashtagModel]
    var isFollowed: Bool
    var isFollower: Bool
    
    private enum CodingKeys: String, CodingKey {
        case id, avatar, fullName, address, gender, birthday, hashtags, isFollowed, isFollower
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(.id)
        avatar = try? container.decode(.avatar)
        fullName = try container.decode(.fullName)
        address = try? container.decode(.address)
        gender = try? container.decode(.gender)
        
        if let timestamp: Double = try? container.decode(.birthday) {
            birthday = Date(timeIntervalSince1970: timestamp)
        } else {
            birthday = nil
        }
        
        hashtags = (try? container.decode(.hashtags)) ?? []
        isFollowed = (try? container.decode(.isFollowed)) ?? false
        isFollower = (try? container.decode(.isFollower)) ?? false
    }
    
    var genderString: String? {
        guard let gender = gender else { return nil }
        return gender == .notSelected ? nil : "\(R.string.localizable.genderTitle()): \(gender.rawValue)"
    }
}
