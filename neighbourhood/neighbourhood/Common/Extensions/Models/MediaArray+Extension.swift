//
//  MediaArray+Extension.swift
//  neighbourhood
//
//  Created by Artem Korzh on 31.03.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import Foundation

extension Array where Element == MediaDataModel {
    var audios: [MediaDataModel] {
        return self.filter({$0.type == .voice})
    }

    var videos: [MediaDataModel] {
        return self.filter({$0.type == .video})
    }

    var images: [MediaDataModel] {
        return self.filter({$0.type == .image})
    }
}
