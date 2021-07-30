//
//  AddBusinessProfileCell.swift
//  neighbourhood
//
//  Created by Dioksa on 04.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

final class AddBusinessProfileCell: UITableViewCell {
    @IBOutlet private weak var addAccountTitle: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setTexts()
        selectionStyle = .none
    }

    private func setTexts() {
        addAccountTitle.text = R.string.localizable.addBusinessProfileTitle()
    }
}
