//
//  CALayer+Extension.swift
//  neighbourhood
//
//  Created by Artem Korzh on 20.01.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import UIKit

extension CALayer {
    public func copy() -> Self? {
        do {
            let archivedLayer = try NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
            let copiedLayer = NSKeyedUnarchiver.unarchiveObject(with: archivedLayer) as? Self
            return copiedLayer
        } catch {}
        return nil
    }
}
