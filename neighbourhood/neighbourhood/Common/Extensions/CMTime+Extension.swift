//
//  CMTime+Extension.swift
//  neighbourhood
//
//  Created by Artem Korzh on 02.09.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import AVFoundation

extension CMTime {
    var timeInterval: TimeInterval? {
        let seconds = CMTimeGetSeconds(self)
        if seconds.isNaN {
            return nil
        }
        return TimeInterval(seconds)
    }
}
