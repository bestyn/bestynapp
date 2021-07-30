//
//  BusinessProfileCell.swift
//  neighbourhood
//
//  Created by Dioksa on 05.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

final class BusinessProfileCell: UITableViewCell {
    @IBOutlet private weak var businessAccountTitleLabel: UILabel!
    @IBOutlet private weak var userNameLabel: UILabel!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var unreadView: UIView!
    @IBOutlet weak var avatarView: MediumAvatarView!

    var profile: SelectorProfileModel? {
        didSet { fillData() }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setTexts()
        selectionStyle = .none
    }

    private func fillData() {
        guard let profile = profile else {
            return
        }
        unreadView.isHidden = profile.hasUnreadMessages != true
        userNameLabel.text = profile.fullName
        addressLabel.text = profile.address
        avatarView.isBusiness = profile.type == .business
        avatarView.updateWith(imageURL: profile.avatar?.formatted?.small, fullName: profile.fullName)
        businessAccountTitleLabel.text = profile.type.title
        avatarView.setNeedsLayout()
    }

    private func setTexts() {
        businessAccountTitleLabel.text = R.string.localizable.businessTitle()
    }
}
