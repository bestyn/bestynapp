//
//  ReportCell.swift
//  neighbourhood
//
//  Created by Dioksa on 23.06.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

final class ReportCell: UITableViewCell {
    @IBOutlet private weak var backgroundImageView: UIImageView!
    @IBOutlet private weak var reportNameLabel: UILabel!

    public var title: String! {
        didSet { reportNameLabel.text = title }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        backgroundImageView.image = selected ? R.image.report_selected() : R.image.report_light()
        reportNameLabel.textColor = selected ? .white : R.color.mainBlack()
    }
}
