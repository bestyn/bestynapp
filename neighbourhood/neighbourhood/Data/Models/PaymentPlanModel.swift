//
//  PaymentPlanModel.swift
//  neighbourhood
//
//  Created by Artem Korzh on 19.08.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

enum PaymentPlatform: String, Codable {
    case android = "Android"
    case ios = "iOS"
}

struct PaymentPlanModel: Codable {
    let id: Int
    let platform: PaymentPlatform
    let userID: Int
    let productID: Int
    let productName: String
    let transactionToken: String
    let createdAt: Date

    private enum CodingKeys: String, CodingKey {
        case id, platform, productName, transactionToken, createdAt
        case userID = "userId"
        case productID = "productId"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(.id)
        platform = try container.decode(.platform)
        userID = try container.decode(.userID)
        productID = try container.decode(.productID)
        productName = try container.decode(.productName)
        transactionToken = try container.decode(.transactionToken)
        let createdAtTimestamp: Double = try container.decode(.createdAt)
        createdAt = Date(timeIntervalSince1970: createdAtTimestamp)
    }
}
