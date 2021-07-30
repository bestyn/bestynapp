//
//  AttachmentData.swift
//  neighbourhood
//
//  Created by Artem Korzh on 11.11.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

enum AttachmentData {
    case file(URL)
    case storedImage(URL)
    case capturedImage(UIImage)
    case voice(URL)
    case video(URL)

    var fileName: String {
        switch self {
        case .capturedImage(_):
            return "image.jpg"
        case .file(let url), .storedImage(let url), .video(let url), .voice(let url):
            return url.lastPathComponent
        }
    }
}
