//
//  BasePostCell.swift
//  neighbourhood
//
//  Created by Artem Korzh on 21.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

protocol MenuActionButtonDelegate: AnyObject {
    func openMenu(post: PostModel)
}

protocol PostCellDelegate: AnyObject {
    func openMedia(_ media: MediaDataModel)
    func reloadDescriptionLabel(post: PostModel)
    func followPost(_ post: PostModel)
    func openProfile(post: PostModel)
    func reactionSelected(_ reaction: Reaction, for post: PostModel)
    func reactionRemoved(for post: PostModel)
    func openReactions(post: PostModel)
    func hashtagSelected(_ hashtag: String)
    func mentionSelected(profileId: Int)
    func mediaViewed(media: MediaDataModel)
}

class BasePostCell: UITableViewCell {

    @IBOutlet weak var profileNameLabel: UILabel!
    @IBOutlet weak var postDateLabel: UILabel!
    @IBOutlet weak var followersButton: UIButton!
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var commentsButton: UIButton!
    @IBOutlet weak var avatarView: MediumAvatarView!
    @IBOutlet weak var followedView: UIStackView!
    @IBOutlet weak var reactionsView: ReactionsView!
    @IBOutlet weak var reactionPicker: ReactionPicker!
    @IBOutlet weak var postTypeButton: UIButton!

    weak var actionDelegate: MenuActionButtonDelegate?
    weak var cellDelegate: PostCellDelegate?

    var post: PostModel? {
        didSet { fillData() }
    }

    override var isSelected: Bool {
        didSet { reactionPicker.isHidden = true }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupReactions()
        setupButtons()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        reactionPicker.isHidden = true
        avatarView.isBusiness = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        postTypeButton.cornerRadius = postTypeButton.frame.height / 2
    }

    // MARK: - Overridable

    public func fillAdditionalInfo(from post: PostModel) {}

    // MARK: - Public

    public func hideReactions() {
        reactionPicker.isHidden = true
    }

    // MARK: - Actions

    @IBAction private func likeButtonDidTap(_ sender: UIButton) {
        guard let post = post else {
            return
        }
        if post.myReaction == nil {
            reactionPicker.isHidden.toggle()
        } else {
            cellDelegate?.reactionRemoved(for: post)
        }
    }

    @IBAction private func cellMenuButtonDidTap(_ sender: UIButton) {
        reactionPicker.isHidden = true
        guard let post = post else { return }
        actionDelegate?.openMenu(post: post)
    }

    @IBAction private func followButtonDidTap(_ sender: UIButton) {
        reactionPicker.isHidden = true
        guard let post = post else {
            return
        }
        followButton.isHidden = true
        cellDelegate?.followPost(post)
    }

    @IBAction func viewPublicProfileButtonDidTap(_ sender: UIButton) {
        reactionPicker.isHidden = true
        guard let post = post else {
            return
        }
        cellDelegate?.openProfile(post: post)
    }
}

// MARK: - Private functions

extension BasePostCell {
    private func setupReactions() {
        reactionPicker.delegate = self
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapReactions))
        reactionsView.addGestureRecognizer(tapRecognizer)
    }

    private func setupButtons() {
        [likeButton, followersButton, commentsButton].forEach { (button) in
            button?.imageView?.contentMode = .scaleAspectFit
        }
    }

    @objc private func didTapReactions() {
        reactionPicker.isHidden = true
        guard let post = post else {
            return
        }
        cellDelegate?.openReactions(post: post)
    }
}

// MARK: - Fill with data

extension BasePostCell {
    private func fillData() {
        guard let post = post else {
            return
        }
        setAuthorInfo(post: post)
        setPostDate(post: post)
        updateReactionsInfo(post: post)
        updateFollowInfo(post: post)
        updateCommentInfo(post: post)
        updatePostTypeMark(postType: post.type)

        fillAdditionalInfo(from: post)
    }

    private func setAuthorInfo(post: PostModel) {
        guard let profile = post.profile else {
            return
        }
        profileNameLabel.text = profile.fullName
        avatarView.isBusiness = profile.type == .business
        avatarView.updateWith(imageURL: profile.avatar?.formatted?.small, fullName: profile.fullName)
    }

    private func setPostDate(post: PostModel) {
        if post.createdAt != post.updatedAt {
            postDateLabel.text = "\(post.createdAt.postDateTimeString) \u{2022} \(R.string.localizable.editedTitle())"
        } else {
            postDateLabel.text = post.createdAt.postDateTimeString
        }
    }

    public func updateReactionsInfo(post: PostModel) {
        if let reaction = post.myReaction {
            likeButton.setImage(reaction.reaction.image, for: .normal)
            likeButton.setTitle(reaction.reaction.title, for: .normal)
        } else {
            likeButton.setImage(R.image.reaction_button_icon(), for: .normal)
            likeButton.setTitle(R.string.localizable.react(), for: .normal)
        }
        reactionsView.alpha = post.reactionsCount == 0 ? 0 : 1
        reactionsView.reactions = post.reactions
    }

    public func updateFollowInfo(post: PostModel) {
        followButton.setTitle(post.iFollow ? R.string.localizable.unfollowPostButtonTitle() : R.string.localizable.followPostButtonTitle(), for: .normal)
        followersButton.setTitle(post.followersCount > 0 ? post.followersCount.counter() : nil, for: .normal)
        followButton.isHidden = post.isMy || post.iFollow
        if post.iFollow {
            followersButton.setImage(R.image.follow_selected_icon(), for: .normal)
            followersButton.setTitleColor(R.color.accent3(), for: .normal)
            followedView.isHidden = false
            followButton.isHidden = true
        } else {
            followersButton.setImage(R.image.follow_icon(), for: .normal)
            followersButton.setTitleColor(R.color.mainBlack(), for: .normal)
            followedView.isHidden = true
            followButton.isHidden = post.isMy
        }
    }

    public func updateCommentInfo(post: PostModel) {
        commentsButton.setImage(post.messagesCount > 0 ? R.image.comments_icon() : R.image.comments_icon_grey(), for: .normal)
        commentsButton.setTitle(post.messagesCount > 0 ? post.messagesCount.counter() : nil, for: .normal)
    }

    private func updatePostTypeMark(postType: TypeOfPost) {
        postTypeButton.alpha = postType == .general ? 0 : 1

        postTypeButton.backgroundColor = postType.markBackgroundColor
        postTypeButton.setTitleColor(postType.markTextColor, for: .normal)
        postTypeButton.setTitle(postType.rawValue.capitalizingFirstLetter(), for: .normal)
    }
}

// MARK: - ReactionPickerDelegate

extension BasePostCell: ReactionPickerDelegate {
    func reactionSelected(_ reaction: Reaction) {
        guard let post = post else {
            return
        }
        cellDelegate?.reactionSelected(reaction, for: post)
        reactionPicker.isHidden = true
    }
}
