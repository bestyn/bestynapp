//
//  ReactionCell.swift
//  neighbourhood
//
//  Created by Artem Korzh on 19.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

protocol ReactionCellDelegate: class {
    func openChat(with profile: PostProfileModel)
}

class ReactionCell: UITableViewCell {

    @IBOutlet weak var avatarView: MediumAvatarView!
    @IBOutlet weak var reactionImageView: UIImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var chatButtonWrapper: UIView!
    @IBOutlet weak var chatButton: UIButton!

    public weak var delegate: ReactionCellDelegate?

    public var reaction: PostReactionModel? {
        didSet { fillData() }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupLayout()
    }

    @IBAction func didTapChat(_ sender: Any) {
        if let profile = reaction?.profile {
            delegate?.openChat(with: profile)
        }
    }
}

extension ReactionCell {

    private func setupLayout() {
        chatButtonWrapper.cornerRadius = 20
        chatButton.cornerRadius = 14
    }

    private func fillData() {
        guard let reaction = reaction,
              let profile = reaction.profile else {
            return
        }

        avatarView.isBusiness = profile.type == .business
        avatarView.updateWith(imageURL: profile.avatar?.formatted?.medium, fullName: profile.fullName)
        fullNameLabel.text = profile.fullName
        reactionImageView.image = reaction.reaction.image

        chatButtonWrapper.isHidden = profile.id == ArchiveService.shared.currentProfile?.id
    }
}
