//
//  StoriesListViewController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 15.02.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import UIKit

protocol StoriesListViewControllerDelegate: class {
    func commentsViewShown()
    func commentsViewHidden()
    func commentsPresenterViewController() -> UIViewController
    func isUserAuthorized(completion: @escaping (Bool) -> Void)
}

class StoriesListViewController: BaseViewController {

    @IBOutlet weak var storiesTableView: UITableView!
    @IBOutlet weak var emptyView: UIStackView!
    @IBOutlet weak var emptyLabel: UILabel!
    @IBOutlet weak var emptyButton: LightButton!
    @IBOutlet weak var backButton: UIButton!

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    override var navigationController: UINavigationController? {
        parent?.navigationController ?? super.navigationController
    }
    private var presenterViewController: UIViewController {
        delegate?.commentsPresenterViewController() ?? self
    }
    private var commentsController: StoryCommentsViewController?
    private let viewModel: StoriesListViewModel
    private lazy var currentStory: StoryListModel? = {
        guard let story =  ArchiveService.shared.lastVisitedStory else {
            return nil
        }
        return viewModel.stories.first(where: {$0.story.id == story.id})
    }()

    public weak var delegate: StoriesListViewControllerDelegate?
    public var withBackButton: Bool = false

    init(mode: StoriesListViewModel.Mode, anchorStory: PostModel?) {
        viewModel = .init(mode: mode, anchorStory: anchorStory)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupViewModel()
        setupBackButton()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pauseAll()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playCurrent()
    }

    @IBAction func didTapBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    @IBAction func didTapCreateStory(_ sender: Any) {
        createStory()
    }
}

// MARK: - Configuration

extension StoriesListViewController {
    private func setupTableView() {
        storiesTableView.contentInsetAdjustmentBehavior = .never
        storiesTableView.estimatedRowHeight = UIScreen.main.bounds.height
        storiesTableView.register(R.nib.storyCell)
    }

    private func setupViewModel() {
        viewModel.$stories.bind { [weak self] (stories) in
            self?.storiesTableView.reloadData()
            if let currentStoryIndex = stories.firstIndex(where: {$0.story.id == self?.currentStory?.story.id}) {
                self?.storiesTableView.contentOffset = CGPoint(x: 0, y: CGFloat(currentStoryIndex) * UIScreen.main.bounds.height)
            }
            self?.updateEmptyState(isEmpty: stories.count == 0)
            if let self = self ,
               self.isViewLoaded, self.view.window != nil {
                self.playCurrent()
            }
        }
        viewModel.$lastError.bind { [weak self] (error) in
            if let error = error {
                self?.handleError(error)
            }
        }
    }

    private func setupBackButton() {
        backButton.isHidden = !withBackButton
    }
}

// MARK: - Private methods

extension StoriesListViewController {

    private func updateEmptyState(isEmpty: Bool) {
        storiesTableView.isHidden = isEmpty
        emptyView.isHidden = !isEmpty
        guard isEmpty else {
            return
        }
        switch viewModel.mode {
        case .all, .audio:
            emptyLabel.text = R.string.localizable.emptyStories()
            emptyButton.isHidden = true
        case .my:
            emptyLabel.text = R.string.localizable.emptyStories()
            emptyButton.isHidden = false
            emptyButton.setTitle(R.string.localizable.createStory(), for: .normal)
        case .followed:
            if ArchiveService.shared.interestExist {
                emptyLabel.text = R.string.localizable.emptyRecommendedStories()
                emptyButton.isHidden = true
            } else {
                emptyLabel.text = R.string.localizable.emptyRecommendedStoriesNoInterests()
                emptyButton.setTitle(R.string.localizable.myInterestsTitle(), for: .normal)
                emptyButton.isHidden = false
            }
        }
    }

    func pauseAll() {
        for cell in storiesTableView.visibleCells {
            (cell as? StoryCell)?.pause()
        }
    }

    func playCurrent() {
        guard let currentCell = storiesTableView.visibleCells.first else {
            return
        }
        (currentCell as? StoryCell)?.play()
    }

    private func canHandleUserAction(onSuccess: @escaping () -> Void) {
        delegate?.isUserAuthorized(completion: { (isAuthorized) in
            if isAuthorized {
                onSuccess()
            }
        })
    }

    private func showMenuAlert(story: StoryListModel) {
        let controller = EntityMenuController(entity: story)
        controller.onMenuSelected = { [weak self] (type, story) in
            guard let self = self else {
                return
            }
            switch type {
            case .report:
                BasicProfileRouter(in: self.navigationController).openReportViewController(for: story.story)
            case .copy:
                UIPasteboard.general.string = story.story.description
            case .openChat:
                if let profile = story.story.profile?.chatProfile {
                    ChatRouter(in: self.navigationController).opeChatDetailsViewController(with: profile)
                }
            case .downloadVideo:
                guard let url = story.story.media?.first?.origin else {
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
            case .edit:
                CreateStoryRouter(in: RootRouter.shared.rootNavigationController).openEditStory(storyPost: story.story)
            case .unfollow:
                self.viewModel.unfollow(story: story.story)
            case .delete:
                Alert(title: nil, message: Alert.Message.deleteStory)
                    .configure(doneText: Alert.Action.delete)
                    .configure(cancelText: Alert.Action.cancel)
                    .show { [weak self] (result) in
                        if result == .done {
                            self?.viewModel.remove(story: story.story)
                        }
                    }
            case .createDuet:
                if StorySaver.shared.isPublishing {
                    Toast.show(message: "Sorry, your story is publishing. Please wait")
                    return
                }
                CreateStoryRouter(in: self.navigationController).openCreateDuet(with: story.story)
            default:
                break
            }
        }
        present(controller.alertController, animated: true)
    }

    private func openStoryCreation() {
        if StorySaver.shared.isPublishing {
            Toast.show(message: "Sorry, your story is publishing. Please wait")
            return
        }
        guard RecordVoiceViewModel.shared.checkVoiceRecording() else {
            return
        }
        if ArchiveService.shared.hasPostedStories {
            CreateStoryRouter(in: navigationController).openCreateStory()
            return
        }
        Alert(title: Alert.Title.createStory, message: Alert.Message.createStory)
            .configure(doneText: Alert.Action.getStarted)
            .show { _ in
                ArchiveService.shared.hasPostedStories = true
                CreateStoryRouter(in: self.navigationController).openCreateStory()
            }
    }

    private func navigateToProfile(story: PostModel) {
        if story.isMy {
            MainScreenRouter(in: navigationController).openMyProfile()
            return
        }
        guard let profile = story.profile else {
            return
        }
        switch profile.type {
        case .basic:
            BasicProfileRouter(in: navigationController).openPublicProfileViewController(profileId: profile.id)
        case .business:
            BusinessProfileRouter(in: navigationController).openPublicProfileController(id: profile.id)
        }
    }

    private func saveLastVisitedStory() {
        guard case .all = viewModel.mode else {
            return
        }
        guard let currentStoryIndex = storiesTableView.indexPathsForVisibleRows?.first?.row else {
            return
        }
        ArchiveService.shared.lastVisitedStory = viewModel.stories[currentStoryIndex].story

    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension StoriesListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.stories.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.storyCell, for: indexPath)!
        cell.storyListModel = viewModel.stories[indexPath.row]
        cell.delegate = self
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UIScreen.main.bounds.height
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        currentStory = viewModel.stories[indexPath.row]
        if indexPath.row == 0 {
            viewModel.loadPreviousStories()
        }
        if indexPath.row == viewModel.stories.count - 1 {
            viewModel.loadNextStories()
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        pauseAll()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        playCurrent()
        saveLastVisitedStory()
    }

}

// MARK: - StoryCellDelegate

extension StoriesListViewController: StoryCellDelegate {
    func removeReaction(story: StoryListModel) {
        viewModel.removeReaction(story: story.story)
    }

    func addReaction(story: StoryListModel, reaction: Reaction) {
        canHandleUserAction { [weak self] in
            self?.viewModel.addReaction(story: story.story, reaction: reaction)
        }
    }

    func openMenu(story: StoryListModel) {
        canHandleUserAction { [weak self] in
            self?.showMenuAlert(story: story)
        }
    }

    func openComments(story: StoryListModel) {
        canHandleUserAction { [weak self] in
            self?.openCommentsView(story: story.story)
        }
    }

    func toggleFollow(story: StoryListModel) {
        canHandleUserAction { [weak self] in
            story.story.iFollow
                ? self?.viewModel.unfollow(story: story.story)
                : self?.viewModel.follow(story: story.story)
        }

    }

    func createStory() {
        canHandleUserAction { [weak self] in
            self?.openStoryCreation()
        }
    }

    func hashtagSelected(_ hashtag: String) {
        canHandleUserAction { [weak self] in
            guard let self = self else {
                return
            }
            MyPostsRouter(in: self.navigationController).openHashtagPage(hashtag: hashtag)
        }
    }

    func openProfile(story: StoryListModel) {
        canHandleUserAction { [weak self] in
            self?.navigateToProfile(story: story.story)
        }
    }

    func audioTapped(_ audio: AudioTrackModel) {
        canHandleUserAction { [weak self] in
            guard let self = self else {
                return
            }
            SearchRouter(in: self.navigationController).openAudioDetails(for: audio)
        }
    }

    func canShowReactionPicker(completion: @escaping () -> Void) {
        canHandleUserAction(onSuccess: completion)
    }

    func mentionSelected(profileId: Int) {
        profileNavigationResolver.openProfile(profileId: profileId)
    }
}

// MARK: - Comments View

extension StoriesListViewController {
    private func openCommentsView(story: PostModel) {
        let commentsController = StoryCommentsViewController(currentPost: story)
        let pullableView = BottomPullableView(nestedView: commentsController.view)
        presenterViewController.view.addSubview(pullableView)
        presenterViewController.addChild(commentsController)
        commentsController.didMove(toParent: presenterViewController)
        pullableView.onPullDown = {
            self.closeCommentsView()
        }
        pullableView.configureBackView = { backView in
            backView.layer.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.2).cgColor
            backView.layer.borderWidth = 1
            backView.layer.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5).cgColor

            if !UIAccessibility.isReduceTransparencyEnabled {
                let blurEffect = UIBlurEffect(style: .extraLight)
                let blurEffectView = UIVisualEffectView(effect: blurEffect)

                blurEffectView.frame = backView.bounds
                blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

                blurEffectView.translatesAutoresizingMaskIntoConstraints = false
                blurEffectView.alpha = 0.9
                backView.insertSubview(blurEffectView, at: 0)
            }
        }

        pullableView.configureIndicatorView = { indicator in
            indicator.backgroundColor = .white
        }

        let closeButton = UIButton()
        closeButton.setImage(R.image.stories_close_icon(), for: .normal)
        closeButton.addTarget(self, action: #selector(closeCommentsView), for: .touchUpInside)
        pullableView.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: pullableView.topAnchor, constant: 15),
            closeButton.trailingAnchor.constraint(equalTo: pullableView.trailingAnchor, constant: -15),
            closeButton.widthAnchor.constraint(equalToConstant: 25),
            closeButton.heightAnchor.constraint(equalToConstant: 25)
        ])

        presenterViewController.view.addSubview(pullableView)
        pullableView.frame = CGRect(origin: CGPoint(x: 0, y: 100), size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - 100))
        pullableView.transform = CGAffineTransform(translationX: 0, y: pullableView.frame.height)
        UIView.animate(withDuration: 0.3) {
            pullableView.transform = .identity
        }
        self.commentsController = commentsController
        delegate?.commentsViewShown()
    }

    @objc private func closeCommentsView() {
        guard let commentsController = commentsController,
              let commentsView = commentsController.view.superview else {
            return
        }
        UIView.animate(withDuration: 0.3) {
            commentsView.transform = CGAffineTransform(translationX: 0, y: commentsView.frame.height)
        } completion: { [weak self] _ in
            commentsController.removeFromParent()
            commentsView.removeFromSuperview()
            self?.delegate?.commentsViewHidden()
        }
    }
}


extension StoriesListViewController: StoriesListViewControllerDelegate {
    func commentsViewShown() {
    }

    func commentsViewHidden() {
    }

    func commentsPresenterViewController() -> UIViewController {
        return self
    }

    func isUserAuthorized(completion: @escaping (Bool) -> Void) {
        completion(true)
    }


}
