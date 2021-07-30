//
//  ProfilesData.swift
//  neighbourhood
//
//  Created by Artem Korzh on 12.03.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import Foundation

struct ProfilesData: Codable {
    var fullName: String? = nil
    var isFollowed: Bool? = nil
    var isFollower: Bool? = nil
    var type: ProfileType?

    var noFilters: Bool {
        if let fullName = fullName, !fullName.isEmpty {
            return false
        }
        if type != nil {
            return false
        }

        return true
    }
}
