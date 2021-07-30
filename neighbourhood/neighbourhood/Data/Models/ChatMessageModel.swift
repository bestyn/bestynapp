//
//  ChatMessageModel.swift
//  neighbourhood
//
//  Created by Dioksa on 26.06.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

struct ChatMessageModel: Codable {
    let id: Int
    let text: String
    var attachment: ChatAttachmentModel?
    var profile: ChatProfile?
    let postId: Int
    let profileId: Int
    let createdAt: Date
    let updatedAt: Date
    
    private enum CodingKeys: String, CodingKey {
        case id, text, attachment, profile, postId, profileId, createdAt, updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(.id)
        text = try container.decode(.text)
        attachment = try? container.decode(.attachment)
        profile = try? container.decode(.profile)
        postId = try container.decode(.postId)
        profileId = try container.decode(.profileId)
        
        let createdAtTimestamp: Double = try container.decode(.createdAt)
            createdAt = Date(timeIntervalSince1970: createdAtTimestamp)

        let updatedAtTimestamp: Double = try container.decode(.updatedAt)
            updatedAt = Date(timeIntervalSince1970: updatedAtTimestamp)
    }
}

struct ChatProfile: Codable {
    let id: Int
    var avatar: ImageModel?
    let fullName: String
    let type: ProfileType
    var isTyping: Bool = false
    var isOnline: Bool

    private enum CodingKeys: String, CodingKey {
        case id, avatar, fullName, type, isOnline
    }

    init(id: Int, avatar: ImageModel?, fullName: String, type: ProfileType, isOnline: Bool) {
        self.id = id
        self.avatar = avatar
        self.fullName = fullName
        self.type = type
        self.isOnline = isOnline
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(.id)
        avatar = try container.decode(.avatar)
        fullName = try container.decode(.fullName)
        type = try container.decode(.type)
        isOnline = (try? container.decode(.isOnline)) ?? false
    }
}

struct ChatAttachmentModel: Codable {
    let id: Int
    let origin: URL
    let originName: String?
    let formatted: AttachmentFormatModel?
    let type: TypeOfAttachment
    let createdAt: Date?
    let updatedAt: Date?
    var additional: ChatAttachmentAdditionalModel?
    
    private enum CodingKeys: String, CodingKey {
        case id, origin, type, createdAt, updatedAt, originName, formatted, additional
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(.id)
        origin = try container.decode(.origin)
        type = try container.decode(.type)
        originName = try? container.decode(.originName)
        formatted = try? container.decode(.formatted)
        additional = try? container.decode(.additional)
        
        if let timestamp: Double = try? container.decode(.createdAt) {
            createdAt = Date(timeIntervalSince1970: timestamp)
        } else {
            createdAt = nil
        }
        
        if let timestamp: Double = try? container.decode(.updatedAt) {
            updatedAt = Date(timeIntervalSince1970: timestamp)
        } else {
            updatedAt = nil
        }
    }
}

struct ChatAttach: Codable {
    let text: String?
    let attachmentId: Int?
    let messageId: Int?
    let postId: Int?
    let profileId: Int
}

struct AttachmentFormatModel: Codable {
    let thumbnail: URL?
    let preview: URL?
    let small: URL?
    let medium: URL?
}

struct ChatAttachmentAdditionalModel: Codable {
    var listened: Bool
}
