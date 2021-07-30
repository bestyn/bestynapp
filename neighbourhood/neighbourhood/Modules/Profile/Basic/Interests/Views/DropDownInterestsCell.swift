//
//  DropDownInterestsCell.swift
//  neighbourhood
//
//  Created by Dioksa on 27.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

final class DropDownInterestsCell: UITableViewCell {
    @IBOutlet private weak var categoryNameLabel: UILabel!

    func updateCell(title: String) {
        categoryNameLabel.text = title
    }
}
