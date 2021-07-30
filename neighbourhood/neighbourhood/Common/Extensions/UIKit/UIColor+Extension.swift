//
//  UIColor+Extension.swift
//  neighbourhood
//
//  Created by Dioksa on 28.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

extension UIColor {

    var hexString: String? {
        if let components = self.cgColor.components {
            let red = components[0]
            let green = components[1]
            let blue = components[2]
            return  String(format: "%02X%02X%02X", (Int)(red * 255), (Int)(green * 255), (Int)(blue * 255))
        }
        return nil
    }
}
