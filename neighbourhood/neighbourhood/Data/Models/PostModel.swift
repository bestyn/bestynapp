//
//  PostModel.swift
//  neighbourhood
//
//  Created by Dioksa on 25.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

enum MediaType: String, Codable {
    case image
    case video
    case voice
}

enum TypeOfPost: String, Hashable, Codable {
    case general
    case news
    case crime
    case offer
    case event
    case onlyBusiness = ""
    case media
    case shared
    case repost
    case story
}

enum Reaction: String, Codable, CaseIterable {
    case like
    case love
    case laugh
    case angry
    case sad
    case top
    case trash
}

struct PostProfileModel: Codable {
    let id: Int
    var fullName: String
    let type: ProfileType
    var avatar: ImageModel?
    var isFollowed: Bool
    var isFollower: Bool

    enum CodingKeys: String, CodingKey {
        case id, fullName, type, avatar, isFollowed, isFollower
    }

    init(id: Int, fullName: String, type: ProfileType, avatar: ImageModel? = nil, isFollowed: Bool?, isFollower: Bool?) {
        self.id = id
        self.fullName = fullName
        self.type = type
        self.avatar = avatar
        self.isFollowed = isFollowed ?? false
        self.isFollower = isFollower ?? false
    }


    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(.id)
        fullName = try container.decode(.fullName)
        type = try container.decode(.type)
        avatar = try? container.decode(.avatar)
        isFollowed = (try? container.decode(.isFollowed)) ?? false
        isFollower = (try? container.decode(.isFollower)) ?? false
    }
}

struct PostModel: Codable {
    let id: Int
    let type: TypeOfPost
    let userId: Int?
    let description: String?
    let address: String?
    let placeId: String?
    let name: String?
    let startDatetime: Date?
    let endDatetime: Date?
    let price: Double?
    let createdAt: Date
    let updatedAt: Date
    var profile: PostProfileModel?
    let categories: [CategoriesData]?
    var media: [MediaDataModel]?
    let iFollow: Bool
    let counters: [String: Int]
    let myReaction: PostReactionModel?
    let allowedComment: Bool
    let allowedDuet: Bool
    let audio: AudioTrackModel?
    
    static func empty(type: TypeOfPost) -> PostModel {
        return PostModel(
            id: 0,
            type: type,
            userId: nil,
            description: nil,
            address: nil,
            placeId: nil,
            name: nil,
            startDatetime: nil,
            endDatetime: nil,
            price: nil,
            createdAt: Date(),
            updatedAt: Date(),
            profile: nil,
            categories: nil,
            media: nil,
            iFollow: false,
            counters: [:],
            myReaction: nil,
            audio: nil
        )
    }
    
    init(
        id: Int,
        type: TypeOfPost,
        userId: Int?,
        description: String?,
        address: String?,
        placeId: String?,
        name: String?,
        startDatetime: Date?,
        endDatetime: Date?,
        price: Double?,
        createdAt: Date,
        updatedAt: Date,
        profile: PostProfileModel?,
        categories: [CategoriesData]?,
        media: [MediaDataModel]?,
        iFollow: Bool,
        counters: [String: Int],
        myReaction: PostReactionModel?,
        audio: AudioTrackModel?
    ) {
        self.id = id
        self.type = type
        self.userId = userId
        self.description = description
        self.address = address
        self.placeId = placeId
        self.name = name
        self.startDatetime = startDatetime
        self.endDatetime = endDatetime
        self.price = price
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.profile = profile
        self.categories = categories
        self.media = media
        self.iFollow = iFollow
        self.counters = counters
        self.myReaction = myReaction
        self.allowedComment = true
        self.audio = audio
        self.allowedDuet = false
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, type, userId, description, address, name, startDatetime, endDatetime, price, placeId
        case createdAt, updatedAt, profile, categories, media
        case iFollow
        case counters, myReaction, allowedComment, allowedDuet
        case audio
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(.id)
        type = try container.decode(.type)
        userId = try? container.decode(.userId)

        description = try container.decode(.description)
        name = try? container.decode(.name)
        address = try? container.decode(.address)
        placeId = try? container.decode(.placeId)
         
        if let timestamp: Double = try? container.decode(.startDatetime) {
            startDatetime = Date(timeIntervalSince1970: timestamp)
        } else {
            startDatetime = nil
        }
        
        if let timestamp: Double = try? container.decode(.endDatetime) {
            endDatetime = Date(timeIntervalSince1970: timestamp)
        } else {
            endDatetime = nil
        }
        
        price = try? container.decode(.price)

        let createdAtTimestamp: Double = try container.decode(.createdAt)
        createdAt = Date(timeIntervalSince1970: createdAtTimestamp)
        let updatedAtTimestamp: Double = try container.decode(.updatedAt)
        updatedAt = Date(timeIntervalSince1970: updatedAtTimestamp)

        profile = try? container.decode(.profile)
        categories = try? container.decode(.categories)
        media = try? container.decode(.media)
        iFollow = (try? container.decode(.iFollow)) ?? false
        counters = try container.decode(.counters)
        myReaction = try? container.decode(.myReaction)
        allowedComment = (try? container.decode(.allowedComment)) ?? false
        audio = try? container.decode(.audio)
        allowedDuet = (try? container.decode(.allowedDuet)) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(userId, forKey: .userId)

        try container.encode(description, forKey: .description)
        try container.encode(name, forKey: .name)
        try container.encode(address, forKey: .address)
        try container.encode(placeId, forKey: .placeId)

        try container.encode(startDatetime?.timeIntervalSince1970, forKey: .startDatetime)
        try container.encode(endDatetime?.timeIntervalSince1970, forKey: .endDatetime)

        try container.encode(price, forKey: .price)

        try container.encode(createdAt.timeIntervalSince1970, forKey: .createdAt)
        try container.encode(updatedAt.timeIntervalSince1970, forKey: .updatedAt)

        try container.encode(profile, forKey: .profile)
        try container.encode(categories, forKey: .categories)
        try container.encode(media, forKey: .media)
        try container.encode(iFollow, forKey: .iFollow)
        try container.encode(counters, forKey: .counters)
        try container.encode(myReaction, forKey: .myReaction)
        try container.encode(allowedComment, forKey: .allowedComment)
        try container.encode(audio, forKey: .audio)
        try container.encode(allowedDuet, forKey: .allowedDuet)
    }

    var isMy: Bool {
        guard let currentProfileID = ArchiveService.shared.currentProfile?.id else {
            return false
        }
        return currentProfileID == profile?.id
    }

    var reactions: [Reaction: Int] {
        var reactions: [Reaction: Int] = [:]
        for counter in counters {
            if let reaction = Reaction(rawValue: counter.key) {
                reactions[reaction] = counter.value
            }
        }
        return reactions
    }

    var followersCount: Int { counters["followers"] ?? 0 }
    var reactionsCount: Int { counters["reactions"] ?? 0 }
    var messagesCount: Int { counters["messages"] ?? 0 }
}


extension PostModel: Equatable {
    static func == (lhs: PostModel, rhs: PostModel) -> Bool {
        lhs.id == rhs.id
    }
}

struct StoryListModel: Codable {
    let story: PostModel

    init(story: PostModel) {
        self.story = story
    }

    init(from decoder: Decoder) throws {
        story = try PostModel(from: decoder)
    }
}
