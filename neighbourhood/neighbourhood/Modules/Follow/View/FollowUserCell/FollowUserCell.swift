//
//  FollowUserCell.swift
//  neighbourhood
//
//  Created by Artem Korzh on 02.03.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import UIKit

protocol FollowUserCellDelegate: class {
    func toggleFollow(profile: PostProfileModel)
    func openMenu(profile: PostProfileModel)
}

class FollowUserCell: UITableViewCell {

    @IBOutlet weak var avatarView: MediumAvatarView!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!

    var profile: PostProfileModel! {
        didSet { fillData() }
    }
    var isFollowed: Bool = false
    weak var delegate: FollowUserCellDelegate?

    @IBAction func didTapToggleFollow(_ sender: Any) {
        delegate?.toggleFollow(profile: profile)
    }

    @IBAction func didTapMenu(_ sender: Any) {
        delegate?.openMenu(profile: profile)
    }

    private func fillData() {
        let avatarURL = profile.avatar?.formatted?.medium ?? profile.avatar?.origin
        avatarView.isBusiness = profile.type == .business
        avatarView.updateWith(imageURL: avatarURL, fullName: profile.fullName)
        fullNameLabel.text = profile.fullName
        followButton.setTitleColor( profile.isFollowed ? R.color.greyLight() : R.color.blueButton(), for: .normal)
        followButton.borderColor = profile.isFollowed ? R.color.greyLight() : R.color.blueButton()
        let followButtonTitle: String = {
            if profile.isFollowed {
                return "Following"
            }
            return isFollowed ? "Follow" : "Follow Back"
        }()
        followButton.setTitle(followButtonTitle, for: .normal)
    }
}
