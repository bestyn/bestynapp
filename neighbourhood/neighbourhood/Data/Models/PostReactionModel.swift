//
//  PostReactionModel.swift
//  neighbourhood
//
//  Created by Artem Korzh on 13.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

struct PostReactionModel: Codable {
    let postId: Int
    let profileId: Int
    let reaction: Reaction
    let profile: PostProfileModel?
}
