//
//  UserAvatar.swift
//  neighbourhood
//
//  Created by Dioksa on 30.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

struct ImageModel: Codable {
    let id: Int
    let origin: URL
    let formatted: FormattedImageModel?
    let createdAt: Int
}

extension ImageModel {
    init?(post: PostModel) {
        guard post.type == .media,
              let media = post.media?.first else {
            return nil
        }
        self.id = post.id
        self.origin = media.origin
        self.formatted = media.formatted
        self.createdAt = Int(media.createdAt.timeIntervalSince1970)
    }
}

struct FormattedImageModel: Codable {
    let medium: URL?
    let origin: URL?
    let small: URL?
    let preview: URL?
    let thumbnail: URL?
}

struct ImageUploadResponseModel: Codable {
    let id: Int
    let createdAt: Int
}
