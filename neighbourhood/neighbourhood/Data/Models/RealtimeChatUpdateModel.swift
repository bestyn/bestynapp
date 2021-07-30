//
//  RealtimeChatUpdateModel.swift
//  neighbourhood
//
//  Created by Dioksa on 14.07.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

enum RealtimeAction: String, Codable {
    case create, delete, update
}

struct RealtimeChatUpdateModel: Codable {
    let action: RealtimeAction
    let data: ChatMessageModel
}

struct RealtimePrivateChatUpdateModel: Codable {
    let action: RealtimeAction
    let data: PrivateChatMessageModel
    let extraData: ExtraDataModel?
}

struct RealtimePrivateChatTypingModel: Codable {
    let data: TypingModel
}

struct TypingModel: Codable {
    let isTyping: Bool
    let profileId: Int
}
