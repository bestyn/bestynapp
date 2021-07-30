//
//  EmptyChatCell.swift
//  neighbourhood
//
//  Created by Dioksa on 26.06.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

final class EmptyChatCell: UITableViewCell {
    @IBOutlet private weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.text = R.string.localizable.emptyCommentPublicScreen()
        selectionStyle = .none
    }
}
