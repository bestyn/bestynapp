//
//  TimeInterval+Extension.swift
//  neighbourhood
//
//  Created by Artem Korzh on 02.09.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

extension TimeInterval {
    var displayTime: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%02i:%02i", minutes, seconds)
    }
}
