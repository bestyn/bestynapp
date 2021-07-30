//
//  CurrentProfileCell.swift
//  neighbourhood
//
//  Created by Artem Korzh on 19.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

class CurrentProfileCell: UITableViewCell {

    @IBOutlet weak var avatarView: AvatarView!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!

    var profile: SelectorProfileModel? {
        didSet { fillData() }
    }

    private func fillData() {
        guard let profile = profile else {
            return
        }
        avatarView.isBusiness = profile.type == .business
        avatarView.updateWith(imageURL: profile.avatar?.formatted?.medium, fullName: profile.fullName)
        fullNameLabel.text = profile.fullName
        addressLabel.text = profile.address
    }
}
