//
//  MentionCell.swift
//  neighbourhood
//
//  Created by Artem Korzh on 15.03.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import UIKit

class MentionCell: UITableViewCell {

    @IBOutlet weak var avatarView: SmallAvatarView!
    @IBOutlet weak var fullNameLabel: UILabel!


    public var profile: PostProfileModel! {
        didSet { fillData() }
    }

    private func fillData() {
        let imageURL = profile.avatar?.formatted?.small ?? profile.avatar?.origin
        avatarView.updateWith(imageURL: imageURL, fullName: profile.fullName)
        fullNameLabel.text = profile.fullName
    }
}
