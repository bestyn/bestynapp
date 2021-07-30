//
//  Int+Extension.swift
//  neighbourhood
//
//  Created by Artem Korzh on 28.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

extension IntegerLiteralType {
    func counter(max: Int = 999) -> String {
        self > max ? "\(max)+" : "\(self)"
    }
}

