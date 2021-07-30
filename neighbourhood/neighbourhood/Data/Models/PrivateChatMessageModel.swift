//
//  PrivateChatMessageModel.swift
//  neighbourhood
//
//  Created by Dioksa on 16.07.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

struct PrivateChatMessageModel: Codable {
    let id: Int
    let text: String
    var isRead: Bool
    var attachment: ChatAttachmentModel?
    let senderProfileId: Int
    let recipientProfileId: Int
    let createdAt: Date
    let updatedAt: Date
    let senderProfile: ChatProfile?
    let recipientProfile: ChatProfile?
    
    private enum CodingKeys: String, CodingKey {
        case id, text, isRead, attachment, senderProfileId, recipientProfileId, createdAt
        case updatedAt, senderProfile, recipientProfile
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(.id)
        text = try container.decode(.text)
        isRead = (try? container.decode(.isRead)) ?? false
        attachment = try container.decode(.attachment)
        senderProfileId = try container.decode(.senderProfileId)
        recipientProfileId = try container.decode(.recipientProfileId)
        
        let createdAtTimestamp: Double = try container.decode(.createdAt)
            createdAt = Date(timeIntervalSince1970: createdAtTimestamp)

        let updatedAtTimestamp: Double = try container.decode(.updatedAt)
            updatedAt = Date(timeIntervalSince1970: updatedAtTimestamp)

        senderProfile = try? container.decode(.senderProfile)
        recipientProfile = try? container.decode(.recipientProfile)
    }
}
