//
//  Reaction+Extension.swift
//  neighbourhood
//
//  Created by Artem Korzh on 13.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

extension Reaction {

    var title: String {
        return rawValue.capitalizingFirstLetter()
    }

    var image: UIImage? {
        return UIImage(named: "reaction_\(rawValue)")
    }
}
