//
//  BasePostListViewController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 07.09.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import GBKSoftRestManager
import AVKit
import GSPlayer

enum PostScreenType {
    case list, details
}

class BasePostListViewController: BaseViewController {

    @IBOutlet private(set) weak var tableView: UITableView!
    @IBOutlet private weak var spinner: UIActivityIndicatorView!

    // MARK: - Private variables

    var posts: [PostModel] = []
    private var postType: TypeOfPost = .general
    private(set) var nextPage = 1
    private var lastPage = 0
    private(set) var loadingPosts = false
    var profileID: Int {
        ArchiveService.shared.currentProfile!.id
    }
    private var interactedPost: PostModel?
    private var cellHeights: [IndexPath: CGFloat] = [:]
    private var expandedPosts: [IndexPath: Bool] = [:]

    private(set) lazy var emptyView: EmptyView = {
        let emptyView = EmptyView()
        emptyView.isHidden = true
        emptyView.frame = CGRect(x: 16, y: tableView.contentOffset.y + 4, width: view.frame.width - 32, height: 80)
        tableView.backgroundView = emptyView
        emptyView.setAttributesForEmptyScreen(text: emptyViewTitle)
        return emptyView
    }()

    // MARK: - Public variables

    lazy var postsManager: RestMyPostsManager = {
        let manager = RestService.shared.createOperationsManager(from: self, type: RestMyPostsManager.self)
        manager.assignErrorHandler { [weak self] (error) in
            self?.handleError(error)
        }
        return manager
    }()

    lazy var reactionsManager: RestReactionsManager = {
        let manager = RestService.shared.createOperationsManager(from: self, type: RestReactionsManager.self)
        manager.assignErrorHandler { [weak self] (error) in
            self?.handleError(error)
        }
        return manager
    }()
    lazy var profileManager: RestProfileManager = {
        let manager = RestService.shared.createOperationsManager(from: self, type: RestProfileManager.self)
        manager.assignErrorHandler { [weak self] (error) in
            self?.handleError(error)
        }
        return manager
    }()

    lazy var businesProfileManager: RestBusinessProfileManager = {
        let manager = RestService.shared.createOperationsManager(from: self, type: RestBusinessProfileManager.self)
        manager.assignErrorHandler { [weak self] (error) in
            self?.handleError(error)
        }
        return manager
    }()
    weak var delegate: SearchFieldUpdatable?
    public var filters: [TypeOfPost] = [] {
        didSet { filterResults() }
    }
    public var searchPostsByString: String = "" {
        didSet { filterResults() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupRefreshHandler()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if posts.count == 0 {
            loadMorePosts()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AudioPlayerService.shared.stop()
    }

    // MARK: - Overridable

    var emptyViewTitle: String {
        fatalError("Empty View content should be set up")
    }

    func fetchPosts() -> PreparedOperation<[PostModel]> {
        fatalError("Fetch should be implemented")
    }

    func postFollowChanged(post: PostModel) {
        restRefreshPost(post)
    }

    func shouldReplace(post: PostModel) -> Bool {
        return true
    }

    func updateEmptyViewState() {
        self.emptyView.setAttributesForEmptyScreen(text: emptyViewTitle)
        self.emptyView.isHidden = posts.count > 0
    }

    @objc func refreshPostsList() {
        reset()
        searchPostsByString = ""
        restLoadMorePosts()
        delegate?.clearTextField()
    }

    func refreshCurrentProfilePosts() {
        guard let currentProfile = ArchiveService.shared.currentProfile else {
            return
        }
        posts = posts.map({ (post) -> PostModel in
            guard post.profile?.id == currentProfile.id else {
                return post
            }
            var post = post
            post.profile?.avatar = currentProfile.avatar
            post.profile?.fullName = currentProfile.fullName
            return post
        })
        tableView.reloadData()
    }
}

// MARK: - Layout

extension BasePostListViewController {

    private func setupTableView() {
        tableView.register(R.nib.postCell)
        tableView.register(R.nib.mediaPostCell)
        tableView.refreshControl = refreshControl
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 70, right: 0)
        tableView.estimatedRowHeight = 800
        tableView.rowHeight = UITableView.automaticDimension
    }

    private func setupRefreshHandler() {
        refreshControl.addTarget(self, action: #selector(refreshPostsList), for: .valueChanged)
    }
}

// MARK: - Posts logic

extension BasePostListViewController {
    private func reset() {
        posts = []
        nextPage = 1
        lastPage = 0
        cellHeights = [:]
        expandedPosts = [:]
    }

    private func filterResults() {
        reset()
        restLoadMorePosts()
    }

    private func loadMorePosts() {
        if loadingPosts {
            return
        }
        if lastPage > 0, lastPage < nextPage {
            return
        }
        restLoadMorePosts()
    }

    public func removePost(_ post: PostModel) {
        if let postIndex = posts.firstIndex(where: {$0.id == post.id}) {
            posts.remove(at: postIndex)
            tableView.deleteRows(at: [IndexPath(row: Int(postIndex), section: 0)], with: .automatic)
            cellHeights.removeAll()
            self.updateEmptyViewState()
        }
    }

    func openCurrentProfilePage() {
        MainScreenRouter(in: navigationController).openMyProfile()
    }
}

// MARK: - REST requests

extension BasePostListViewController {
    private func restLoadMorePosts() {
        fetchPosts()
            .onStateChanged { [weak self] (state) in
                switch state {
                case .started:
                    self?.loadingPosts = true
                    self?.spinner.startAnimating()
                default:
                    break
                }
            }.onError({ [weak self] (error) in
                self?.loadingPosts = false
                self?.spinner.stopAnimating()
                self?.refreshControl.endRefreshing()
                self?.updateEmptyViewState()
                self?.handleError(error)
            })
            .onComplete { [weak self] (response) in
            guard let self = self else {
                return
            }
            if let pagination = response.pagination {
                self.nextPage = pagination.currentPage + 1
                self.lastPage = pagination.pageCount
            }

            if let posts = response.result {
                DispatchQueue.global().async {
                    var processedPosts: [PostModel] = []
                    for post in posts {
                        guard var videoMedia = post.media?.first(where: {$0.type == .video}) else {
                            processedPosts.append(post)
                            continue
                        }
                        var newPost = post
                        if let videoTrack = AVAsset(url: videoMedia.origin).tracks(withMediaType: .video).first {
                            let ratio = videoTrack.naturalSize.height / videoTrack.naturalSize.width
                            videoMedia.videoRatio = Double(ratio)
                            newPost.media = newPost.media?.map({ (media) -> MediaDataModel in
                                if media.id == videoMedia.id {
                                    return videoMedia
                                }
                                return media
                            })
                        }
                        processedPosts.append(newPost)
                    }

                    DispatchQueue.main.async {
                        if !self.posts.contains(where: {$0.id == processedPosts.first?.id}) {
                            self.posts.append(contentsOf: processedPosts)
                        }
                        let mediaToPreload = processedPosts.reduce([URL]()) { (result, post) -> [URL] in
                            var result = result
                            if let urlsToAdd = post.media?.compactMap({ (media) -> URL? in
                                switch media.type {
                                case .video:
                                    return media.formatted?.origin
                                case .voice:
                                    return media.origin
                                case .image:
                                    return nil
                                }
                            }) {
                                result.append(contentsOf: urlsToAdd)
                            }
                            return result
                        }
                        VideoPreloadManager.shared.set(waiting: mediaToPreload)
                        self.tableView.reloadData()
                        self.loadingPosts = false
                        self.spinner.stopAnimating()
                        self.refreshControl.endRefreshing()
                        self.updateEmptyViewState()
                    }
                }
            }
            }.run()
    }

    private func restRefreshPost(_ post: PostModel) {
        postsManager.getPost(postId: post.id)
            .onComplete { (response) in
                guard let updatedPost = response.result else {
                        return
                }
                NotificationCenter.default.post(name: .postUpdated, object: updatedPost)
        }.run()
    }

    private func restRemovePost(_ post: PostModel) {
        postsManager.deletePost(postId: post.id)
            .onComplete { [weak self] (response) in
                guard let self = self,
                    let postIndex = self.posts.firstIndex(where: { $0.id == post.id }) else {
                        return
                }
                self.posts.remove(at: postIndex)
                NotificationCenter.default.post(name: .postRemoved, object: post)
                self.tableView.deleteRows(at: [IndexPath(row: Int(postIndex), section: 0)], with: .automatic)
                let message = post.type.deleteSuccessMessage
                Toast.show(message: message)
                self.updateEmptyViewState()
        }.run()
    }

    private func restToggleFollow(post: PostModel) {
        let operation = post.iFollow
            ? postsManager.unfollowPost(postId: post.id)
            : postsManager.followPost(postId: post.id)

        operation
            .onComplete { [weak self] (response) in
                self?.postFollowChanged(post: post)
        }.run()
    }

    private func restAddReaction(post: PostModel, reaction: Reaction) {
        reactionsManager.addReaction(postID: post.id, reaction: reaction)
            .onComplete { [weak self] (_) in
                self?.restRefreshPost(post)
            }.run()
    }

    private func restRemoveReaction(post: PostModel) {
        reactionsManager.removeReaction(postID: post.id)
            .onComplete { [weak self] (_) in
                self?.restRefreshPost(post)
            }.run()
    }

    // FIXME: - move all logic in one place instead of copying
    private func restSetAsAvatar(image: UIImage) {
        guard let currentProfile = ArchiveService.shared.currentProfile else {
            return
        }
        if currentProfile.type == .business {
            businesProfileManager.updateProfile(id: currentProfile.id, data: nil, image: image)
                .onComplete { (result) in
                    if let profile = result.result {
                        var user = ArchiveService.shared.userModel
                        let businessProfiles = user?.businessProfiles?.map({ (businesProfile) -> BusinessProfile in
                            if businesProfile.id == profile.id {
                                return profile
                            }
                            return businesProfile
                        })
                        user?.businessProfiles = businessProfiles
                        ArchiveService.shared.userModel = user
                        ArchiveService.shared.currentProfile = profile.selectorProfile
                        Toast.show(message: R.string.localizable.avatarChanged())
                    }
                }.run()
        } else {
            profileManager.changeUserProfile(data: nil, image: image)
                .onComplete { (result) in
                    if let profile = result.result {
                        var user = ArchiveService.shared.userModel
                        user?.profile = profile
                        ArchiveService.shared.userModel = user
                        ArchiveService.shared.currentProfile = profile.selectorProfile
                        Toast.show(message: R.string.localizable.avatarChanged())
                    }
                }.run()
        }
    }

    private func restViewMedia(media: MediaDataModel) {
        postsManager.viewMedia(mediaId: media.id).run()
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension BasePostListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard posts.count > 0 else {
            return UITableViewCell()
        }
        let post = posts[indexPath.row]
        let cell: BasePostCell
        switch post.type {
        case .media:
            cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.mediaPostCell, for: indexPath)!
        default:
            cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.postCell, for: indexPath)!
        }
        cell.actionDelegate = self
        cell.cellDelegate = self
        (cell as? PostCell)?.expanded = expandedPosts[indexPath] ?? false
        cell.post = post
        cell.layoutIfNeeded()
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        MyPostsRouter(in: navigationController).openPostDetailsViewController(currentPost: posts[indexPath.row], profileDelegate: self, postDelegate: self)
        tableView.visibleCells.forEach({ ($0 as? BasePostCell)?.hideReactions() })
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.frame.size.height
        if indexPath.row == posts.count - 1 {
            loadMorePosts()
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return cellHeights[indexPath] ??
        return UITableView.automaticDimension
    }
}

// MARK: - PostCellDelegate

extension BasePostListViewController: PostCellDelegate {

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
        if let index = posts.firstIndex(where: {$0.id == post.id}) {
            let indexPath = IndexPath(row: index, section: 0)
            cellHeights.removeValue(forKey: indexPath)
            expandedPosts[indexPath] = true
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }

    func followPost(_ post: PostModel) {
        restToggleFollow(post: post)
    }

    func openProfile(post: PostModel) {
        if post.isMy {
            openCurrentProfilePage()
            return
        }
        guard let profile = post.profile else {
            return
        }
        switch profile.type {
        case .basic:
            BasicProfileRouter(in: navigationController).openPublicProfileViewController(profileId: profile.id)
        case .business:
            BusinessProfileRouter(in: navigationController).openPublicProfileController(id: profile.id)
        }
    }

    func openDetailsScreen(post: PostModel) {
        MyPostsRouter(in: navigationController).openPostDetailsViewController(currentPost: post, profileDelegate: self, postDelegate: self)
    }

    func openReactions(post: PostModel) {
        BottomMenuPresentationManager.present(ReactionsListViewController(post: post), from: self)
    }

    func reactionSelected(_ reaction: Reaction, for post: PostModel) {
        restAddReaction(post: post, reaction: reaction)
    }

    func reactionRemoved(for post: PostModel) {
        restRemoveReaction(post: post)
    }

    func hashtagSelected(_ hashtag: String) {
        MyPostsRouter(in: navigationController).openHashtagPage(hashtag: hashtag)
    }

    func mentionSelected(profileId: Int) {
        profileNavigationResolver.openProfile(profileId: profileId)
    }

    func mediaViewed(media: MediaDataModel) {
        restViewMedia(media: media)
    }
}

// MARK: - MenuActionButtonDelegate

extension BasePostListViewController: MenuActionButtonDelegate {
    func openMenu(post: PostModel) {

        let controller = EntityMenuController(entity: post)
        controller.onMenuSelected = { [weak self] (type, post) in
            guard let self = self else {
                return
            }
            switch type {
            case .edit:
                if post.type == .story {
                    CreateStoryRouter(in: self.navigationController).openEditStory(storyPost: post)
                } else {
                    if PostSaver.shared.checkPostFormAvailability() {
                        BasicProfileRouter(in: self.navigationController).openEditPost(post: post, delegate: self)
                    }
                }
            case .unfollow:
                self.restToggleFollow(post: post)
            case .delete:
                self.deletePost(post)
            case .report:
                BasicProfileRouter(in: self.navigationController).openReportViewController(for: post)
            case .copy:
                self.copyDescription(post)
            case .setAsAvatar:
                self.setAsAvatar(post)
            case .openChat:
                if let profile = post.profile?.chatProfile {
                    ChatRouter(in: self.navigationController).opeChatDetailsViewController(with: profile)
                }
            case .downloadVideo:
                guard let url = post.media?.first?.origin else {
                    return
                }
                Alert(title: Alert.Title.downloadStory, message: Alert.Message.downloadStory)
                    .configure(doneText: Alert.Action.download)
                    .configure(cancelText: Alert.Action.cancel)
                    .show { (result) in
                        if result == .done {
                            DownloadService.saveVideoToGallery(videoURL: url)
                        }
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
        Alert(title: post.type.deleteAlertTitle, message: Alert.Message.deletedPostMessage)
            .configure(doneText: R.string.localizable.yesButtonTitle())
            .configure(cancelText: R.string.localizable.noButtonTitle())
            .show() { [weak self] (result) in
                if result == .done {
                    self?.restRemovePost(post)
                }
        }
    }

    private func setAsAvatar(_ post: PostModel) {
        guard post.type == .media,
              let imageURL = post.media?.first?.formatted?.medium else {
            return
        }
        UIImage.load(from: imageURL) { [weak self] (image) in
            if let image = image {
                self?.restSetAsAvatar(image: image)
            }
        }
    }
}

// MARK: - PrivateProfileDelegate

extension BasePostListViewController: PrivateProfileDelegate {
    func goToCurrentProfile() {
        openCurrentProfilePage()
    }
}

// MARK: - PostFormDelegate

extension BasePostListViewController: PostFormDelegate {

    func newPostAdded(post: PostModel) {
        refreshPostsList()
    }

    func postUpdated(post: PostModel) {
        if let index = posts.firstIndex(where: {$0.id == post.id}) {
            posts[index] = post
            cellHeights.removeValue(forKey: IndexPath(row: index, section: 0))
            tableView.reloadRows(at: [IndexPath(row: Int(index), section: 0)], with: .none)
        }
    }

    func postRemoved(post: PostModel) {
        removePost(post)
    }

}

