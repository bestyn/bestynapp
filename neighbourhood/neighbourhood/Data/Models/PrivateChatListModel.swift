//
//  PrivateChatListModel.swift
//  neighbourhood
//
//  Created by Dioksa on 16.07.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

struct PrivateChatListModel: Codable {
    let id: Int
    let lastMessageId: Int
    let unreadTotal: Int
    let profile: ChatProfile?
    let lastMessage: PrivateChatMessageModel
}
