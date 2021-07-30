//
//  AudioTrackModel.swift
//  neighbourhood
//
//  Created by Artem Korzh on 28.01.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import Foundation

struct AudioTrackModel: Codable {
    let id: Int
    let description: String
    let duration: Int
    let popularity: Int?
    let profileID: Int?
    let url: URL
    let createdAt: Date
    let profile: PostProfileModel?
    let hashtags: [HashtagModel]
    var isFavorite: Bool

    enum CodingKeys: String, CodingKey {
        case id, description, duration, popularity, url, createdAt, profile, hashtags, isFavorite
        case profileID = "profileId"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(.id)
        description = try container.decode(.description)
        duration = (try? container.decode(.duration)) ?? 0
        popularity = try? container.decode(.popularity)
        profileID = try? container.decode(.profileID)
        url = try container.decode(.url)
        let createdAtTimestamp: Int = try container.decode(.createdAt)
        createdAt = Date(seconds: createdAtTimestamp)
        profile = try? container.decode(.profile)
        hashtags = (try? container.decode(.hashtags)) ?? []
        isFavorite = (try? container.decode(.isFavorite)) ?? false
    }
}
