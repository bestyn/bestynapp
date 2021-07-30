//
//  ReportData.swift
//  neighbourhood
//
//  Created by Artem Korzh on 09.11.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

struct ReportData: Encodable {
    let entityID: Int
    let entityType: ReportEntityType
    let reason: ReportReason
    let comment: String?

    private enum CodingKeys: String, CodingKey {
        case reason, comment
        case entityID = "targetEntityId"
        case entityType = "targetEntityType"
    }
}

enum ReportEntityType: String, Codable {
    case post
    case profile
    case audio
}

enum ReportReason: String, Codable {
    case fake
    case privacy
    case vandalism
    case inappropriate
    case spam
    case other
    case plagiarism
}
