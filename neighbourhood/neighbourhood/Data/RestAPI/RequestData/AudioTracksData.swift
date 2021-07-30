//
//  AudioTracksData.swift
//  neighbourhood
//
//  Created by Artem Korzh on 28.01.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import Foundation

struct AudioTracksData {
    let page: Int
    let search: String?
    let onlyMy: Bool
    let isFavorite: Bool?

    var requestData: [String: Codable] {
        var data: [String: Codable] = [
            "page": page,
            "expand": "profile,hashtags,isFavorite"
        ]
        if let search = search {
            data["description"] = search
        }
        if let isFavorite = isFavorite {
            data["isFavorite"] = isFavorite
        }
        if onlyMy {
            data["profileId"] = ArchiveService.shared.currentProfile?.id
            data["sort"] = ["-createdAt"]
        } else {
            data["sort"] = ["-popularity,-createdAt"]
        }

        return data
    }
}
