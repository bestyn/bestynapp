//
//  BasePostCommentCell.swift
//  neighbourhood
//
//  Created by Artem Korzh on 04.09.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

protocol PostCommentCellDelegate: class {
    func profileSelected(for message: ChatMessageModel)
    func cellNeedResize(cell: BasePostCommentCell)
    func mentionSelected(profileId: Int)
}

class BasePostCommentCell: UITableViewCell, OwnerDependantCell {

    @IBOutlet private weak var chatBackgroundView: UIView!
    @IBOutlet private weak var profileNameLabel: UILabel!
    @IBOutlet private weak var messagDateLabel: UILabel!
    @IBOutlet private weak var editLabel: UILabel!
    @IBOutlet private weak var avatarView: SmallAvatarView!

    // MARK: - Public variables

    var message: ChatMessageModel? {
        didSet { fillData() }
    }
    var isIncome: Bool { true }
    weak var delegate: PostCommentCellDelegate?

    // MARK: - Private variables

    private lazy var tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(profileNameTapped))

    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        resetView()
    }

    @IBAction private func profileImageDidTap(_ sender: UIButton) {
        profileNameTapped()
    }

    private func fillData() {
        guard let message = message else {
            return
        }
        profileNameLabel.text = message.profile?.fullName
        editLabel.isHidden = message.createdAt == message.updatedAt
        messagDateLabel.text = message.createdAt.timeString
        loadProfileAvatar(from: message)
        fillSpecificData(message: message)
    }

    private func setupView() {
        selectionStyle = .none
        editLabel.text = "\u{2022} \(R.string.localizable.editedTitle())"
        profileNameLabel.addGestureRecognizer(tapRecognizer)
        setupOwnerDependantView()
        setupSpecificViews()
    }

    private func resetView() {
        avatarView.reset()
        resetSpecificValues()
    }

    private func loadProfileAvatar(from message: ChatMessageModel) {
        guard let profile = message.profile else {
            return
        }
        avatarView.isBusiness = profile.type == .business
        avatarView.updateWith(imageURL: profile.avatar?.formatted?.small, fullName: profile.fullName)
    }

    private func setupOwnerDependantView() {
        chatBackgroundView.cornerRadius = GlobalConstants.Dimensions.messageViewRadius
    }

    @objc private func profileNameTapped() {
        guard let message = message else {
            return
        }
        delegate?.profileSelected(for: message)
    }

    // MARK: - Overridable methods

    func fillSpecificData(message: ChatMessageModel) {}
    func setupSpecificViews() {}
    func resetSpecificValues() {}
}
