//
//  AVAssetTrack+Extension.swift
//  neighbourhood
//
//  Created by Artem Korzh on 09.12.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import AVFoundation

extension AVAssetTrack {

    var orientedSize: CGSize {
        guard mediaType == .video else {
            return .zero
        }
        let txf = preferredTransform;
        let size = naturalSize

        if size.width == txf.tx, size.height == txf.ty {
            return size
        } else if txf.tx == 0, txf.ty == 0 {
            return size
        } else {
            return size.rotated
        }
    }

}
