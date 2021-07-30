//
//  CategoryCell.swift
//  neighbourhood
//
//  Created by Dioksa on 30.06.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

final class CategoryCell: UITableViewCell {
    @IBOutlet private weak var titleLabel: UILabel!
    
    func updateCell(with name: String) {
        titleLabel.text = name
    }
}
