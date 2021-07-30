//
//  CategoriesData.swift
//  neighbourhood
//
//  Created by Dioksa on 29.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

struct CategoriesData: Equatable, Codable {
    let id: Int
    let categoryName: String
    let title: String
    let createdAt: Date?
    let updatedAt: Date?

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
}
