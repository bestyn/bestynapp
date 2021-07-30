//
//  SendMessageModel.swift
//  neighbourhood
//
//  Created by Dioksa on 16.07.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

struct SendMessageData: Codable {
    let text: String?
    let recipientProfileId: Int?
    let attachmentId: Int?
}
