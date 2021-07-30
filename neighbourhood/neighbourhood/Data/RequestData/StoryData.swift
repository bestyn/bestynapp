//
//  StoryData.swift
//  neighbourhood
//
//  Created by Artem Korzh on 07.12.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

struct StoryData: Encodable {
    let description: String
    var allowedComment: Bool = true
    var allowedDuet: Bool = true
    var posterTime: Int? = nil
    var placeId: String? = nil
    var latitude: Float? = nil
    var longitude: Float? = nil
    var audioId: Int? = nil

}
