//
//  TokenModel.swift
//  neighbourhood
//
//  Created by Dioksa on 22.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

struct TokenModel: Codable {
    let token: String
    let refreshToken: String
    let expiredAt: Date

    private enum CodingKeys: String, CodingKey {
        case token, expiredAt, refreshToken
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        token = try container.decode(.token)
        refreshToken = try container.decode(.refreshToken)
        let expiredAtTimestamp: Int = try container.decode(.expiredAt)
        expiredAt = Date(seconds: expiredAtTimestamp)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(token, forKey: .token)
        try container.encode(Int(expiredAt.timeIntervalSince1970), forKey: .expiredAt)
        try container.encode(refreshToken, forKey: .refreshToken)
    }
}
