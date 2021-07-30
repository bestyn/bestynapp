//
//  HashtagModel.swift
//  neighbourhood
//
//  Created by Artem Korzh on 16.11.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

struct HashtagModel: Codable {
    let id: Int
    let name: String
    let featured: Bool
    let popularity: Int


    var hashtag: String {
        return "#\(name)"
    }
}


extension HashtagModel: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
}
