//
//  NeighborModel.swift
//  neighbourhood
//
//  Created by Dioksa on 12.06.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

struct NeighborModel: Codable {
    let id: Int
    let type: ProfileType
    let avatar: URL?
    let fullName: String
    let latitude: Float
    let longitude: Float
}
