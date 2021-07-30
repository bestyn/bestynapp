//
//  UnreadMarkCell.swift
//  neighbourhood
//
//  Created by Artem Korzh on 06.11.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

class UnreadMarkCell: UITableViewCell {

    @IBOutlet weak var unreadMarkLabel: UILabel! {
        didSet { unreadMarkLabel.text = R.string.localizable.unreadMessages() }
    }
    
}
