//
//  MediaData.swift
//  neighbourhood
//
//  Created by Dioksa on 25.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import UIKit

struct MediaDataModel: Codable {
    let id: Int
    let origin: URL
    let formatted: FormattedImageModel?
    let type: MediaType
    let createdAt: Date
    var videoRatio: Double?
    var counters: MediaCountersModel?


    var viewsCount: Int {
        return counters?.views ?? 0
    }
}

struct MediaCountersModel: Codable {
    let views: Int
}
