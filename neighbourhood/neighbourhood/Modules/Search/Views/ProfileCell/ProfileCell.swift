//
//  ProfileCell.swift
//  neighbourhood
//
//  Created by Artem Korzh on 23.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

class ProfileCell: UITableViewCell {

    @IBOutlet weak var avatarView: MediumAvatarView!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var messageView: UIView!

    var profile: PostProfileModel? {
        didSet { fillData() }
    }

    var onMessageTap: ((PostProfileModel) -> Void)?

    private func fillData() {
        guard let profile = profile else {
            return
        }
        avatarView.isBusiness = profile.type == .business
        avatarView.updateWith(imageURL: profile.avatar?.formatted?.medium, fullName: profile.fullName)
        fullNameLabel.text = profile.fullName
        messageView.isHidden = profile.id == ArchiveService.shared.currentProfile?.id
    }


    @IBAction func didTapMessage(_ sender: Any) {
        if let profile = profile {
            onMessageTap?(profile)
        }
    }
}
