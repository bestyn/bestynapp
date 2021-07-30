//
//  UITableViewCell+Extension.swift
//  neighbourhood
//
//  Created by Artem Korzh on 01.09.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import UIKit

extension UITableViewCell {

    var tableView: UITableView? {
        var view = superview
        while !(view is UITableView) && view?.superview != nil  {
            view = view?.superview
        }
        return view as? UITableView
    }
}
