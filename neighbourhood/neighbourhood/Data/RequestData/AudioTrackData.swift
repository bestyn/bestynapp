//
//  AudioTrackData.swift
//  neighbourhood
//
//  Created by Artem Korzh on 11.02.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import Foundation

struct AudioTrackData: Encodable {
    let file: URL
    let trimStart: Double
    let description: String

    enum CodingKeys: String, CodingKey {
        case trimStart, description
    }
}
