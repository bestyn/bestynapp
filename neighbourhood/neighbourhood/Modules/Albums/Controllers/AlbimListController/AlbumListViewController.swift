//
//  AlbumListViewController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 21.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

class AlbumListViewController: UIViewController {

    @IBOutlet weak var avatarView: SmallAvatarView!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var albumTableView: UITableView!

    private let viewModel: AlbumViewModel
    private let selectedPostIndex: Int
    private var justOpen = true
    lazy var profileNavigationResolver = ProfileNavigationResolver(navigationController: navigationController)

    init(profile: SelectorProfileModel, loadedPosts: [PostModel], selectedPostIndex: Int) {
        self.viewModel = AlbumViewModel(profile: profile, loadedPosts: loadedPosts)
        self.selectedPostIndex = selectedPostIndex
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        albumTableView.register(R.nib.mediaPostCell)
        viewModel.$mediaPosts.bind { [unowned self] (_) in
            self.albumTableView.reloadData()
        }
        viewModel.$profile.bind { [unowned self] (_) in
            self.fillProfileInfo()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.justOpen {
            self.justOpen = false
            self.albumTableView.scrollToRow(
                at: IndexPath(row: selectedPostIndex, section: 0),
                at: .top,
                animated: true)
        }
    }

    @IBAction func didTapBackButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    private func fillProfileInfo() {
        avatarView.updateWith(imageURL: viewModel.profile.avatar?.formatted?.small, fullName: viewModel.profile.fullName)
        fullNameLabel.text = R.string.localizable.albumListTitle(viewModel.profile.fullName)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension AlbumListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.mediaPosts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: R.nib.mediaPostCell, for: indexPath)!
        cell.post = viewModel.mediaPosts[indexPath.row]
        cell.cellDelegate = self
        cell.actionDelegate = self
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let post = viewModel.mediaPosts[indexPath.row]
        openDetailsScreen(post: post)
        albumTableView.visibleCells.forEach({ ($0 as? BasePostCell)?.hideReactions() })
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == viewModel.mediaPosts.count - 1 {
            viewModel.loadMore()
        }
    }
}

// MARK: - PostCellDelegate

extension AlbumListViewController: PostCellDelegate {

    func openMedia(_ media: MediaDataModel) {
        if media.type == .image {
            MyPostsRouter(in: navigationController).openImage(imageUrl: media.origin)
            return
        }
        if media.type == .video {
            MyPostsRouter(in: navigationController).openVideo(videoURL: media.origin)
        }
    }

    func reloadDescriptionLabel(post: PostModel) {
        UIView.performWithoutAnimation {
            albumTableView.layoutIfNeeded()
            albumTableView.beginUpdates()
            albumTableView.endUpdates()
            albumTableView.layer.removeAllAnimations()
        }
    }

    func followPost(_ post: PostModel) {
        viewModel.toggleFollow(post: post)
    }

    func openProfile(post: PostModel) {
        navigationController?.popViewController(animated: true)
    }

    func openDetailsScreen(post: PostModel) {
        MyPostsRouter(in: navigationController).openPostDetailsViewController(currentPost: post, profileDelegate: nil, postDelegate: self)
    }

    func openReactions(post: PostModel) {
        BottomMenuPresentationManager.present(ReactionsListViewController(post: post), from: self)
    }

    func reactionSelected(_ reaction: Reaction, for post: PostModel) {
        viewModel.addReaction(post: post, reaction: reaction)
    }

    func reactionRemoved(for post: PostModel) {
        viewModel.removeReaction(post: post)
    }

    func hashtagSelected(_ hashtag: String) {
        MyPostsRouter(in: navigationController).openHashtagPage(hashtag: hashtag)
    }

    func mentionSelected(profileId: Int) {
        profileNavigationResolver.openProfile(profileId: profileId)
    }
    
    func mediaViewed(media: MediaDataModel) {
    }
}

// MARK: - MenuActionButtonDelegate

extension AlbumListViewController: MenuActionButtonDelegate {
    func openMenu(post: PostModel) {

        let controller = EntityMenuController(entity: post)
        controller.onMenuSelected = { [weak self] (type, post) in
            guard let self = self else {
                return
            }
            switch type {
            case .edit:
                BasicProfileRouter(in: self.navigationController).openEditPost(post: post, delegate: self)
            case .unfollow:
                self.viewModel.toggleFollow(post: post)
            case .delete:
                self.deletePost(post)
            case .report:
                BasicProfileRouter(in: self.navigationController).openReportViewController(for: post)
            case .copy:
                self.copyDescription(post)
            case .setAsAvatar:
                self.setAsAvatar(post: post)
            case .openChat:
                if let profile = post.profile?.chatProfile {
                    ChatRouter(in: self.navigationController).opeChatDetailsViewController(with: profile)
                }
            default:
                break
            }
        }
        present(controller.alertController, animated: true)
    }

    private func copyDescription(_ post: PostModel) {
        UIPasteboard.general.string = post.description
    }

    private func deletePost(_ post: PostModel) {
        Alert(title: post.type == .event ? Alert.Title.deleteEvent : Alert.Title.deletePost, message: Alert.Message.deletedPostMessage)
            .configure(doneText: R.string.localizable.yesButtonTitle())
            .configure(cancelText: R.string.localizable.noButtonTitle())
            .show() { [weak self] (result) in
                if result == .done {
                    self?.viewModel.deletePost(post: post)
                }
        }
    }

    private func setAsAvatar(post: PostModel) {
        viewModel.setAsAvatar(post)
    }
}

// MARK: - BottomTabsSwitcherDelegate
extension AlbumListViewController: PostFormDelegate {
    func newPostAdded(post: PostModel) {}

    func postUpdated(post: PostModel) {
        viewModel.updatePost(post: post)
    }

    func postRemoved(post: PostModel) {
        viewModel.removePost(post: post)
    }
}
