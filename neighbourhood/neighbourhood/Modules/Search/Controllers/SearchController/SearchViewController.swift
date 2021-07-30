//
//  SearchViewController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 23.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import TagListView

class SearchViewController: BaseViewController {

    var viewModel: SearchViewModel!

    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var resultsTableView: UITableView!
    @IBOutlet weak var categoriesStackView: UIStackView!

    @IBOutlet var recentSearchesView: UIView!
    @IBOutlet weak var resentSearchesTitleLabel: UILabel!
    @IBOutlet weak var recentSearchesTagListView: TagListView!

    @IBOutlet var emptyView: UIView!
    @IBOutlet weak var emptyMessageLabel: UILabel!


    private var resultsCount: Int {
        switch viewModel.state.currentMode {
        case .posts:
            return viewModel.state.foundPosts.count
        case .people:
            return viewModel.state.foundPeople.count
        case .audio:
            return viewModel.state.foundAudios.count
        }
    }

    private lazy var loadingView: UIView = {
        let view = UIView()
        let indicator = UIActivityIndicatorView()
        view.addSubview(indicator)
        indicator.tintColor = R.color.blueButton()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.startAnimating()
        NSLayoutConstraint.activate([
            indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupViewModel()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AudioPlayerService.shared.stop()
    }

    @IBAction func didTapBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: Configuration

extension SearchViewController {

    private func setupViews() {
        setupLocalizable()
        setupTableView()
        setupFilterButtons()
        setupTextField()
        setupTagListView()
    }

    private func setupViewModel() {
        viewModel = SearchViewModel()
        viewModel.$state.bind(l: handleStateChange)
    }

    private func setupTableView() {
        resultsTableView.register(R.nib.postCell)
        resultsTableView.register(R.nib.mediaPostCell)
        resultsTableView.register(R.nib.profileCell)
        resultsTableView.register(R.nib.audioSearchCell)
        resultsTableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
    }

    private func setupLocalizable() {
        searchTextField.placeholder = R.string.localizable.searchTitle()
        resentSearchesTitleLabel.text = R.string.localizable.recentSearches()
        emptyMessageLabel.text = R.string.localizable.emptySearch(Configuration.appName)
    }

    private func setupTextField() {
        let searchButton = UIButton()
        searchButton.setImage(R.image.search_icon(), for: .normal)
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchButton.heightAnchor.constraint(equalToConstant: 30),
            searchButton.widthAnchor.constraint(equalToConstant: 30),
        ])
        searchButton.backgroundColor = R.color.blueButton()
        searchButton.cornerRadius = 15
        searchTextField.rightView = searchButton
        searchTextField.rightViewMode = .always
        searchButton.tintColor = UIColor.white.withAlphaComponent(0.4)
        searchButton.imageEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        searchButton.addTarget(self, action: #selector(search), for: .touchUpInside)
        let gapView = UIView()
        gapView.frame = CGRect(origin: .zero, size: CGSize(width: 16, height: 30))
        searchTextField.leftView = gapView
        searchTextField.leftViewMode = .always
        searchTextField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
    }

    private func setupFilterButtons() {
        SearchViewModel.SearchMode.allCases.forEach { (mode) in
            let button = self.filterButton()
            button.setTitle(mode.title, for: .normal)
            categoriesStackView.addArrangedSubview(button)
        }
    }

    private func filterButton() -> UIButton {
        let button = UIButton()
        button.setBackgroundColor(color: R.color.greyBackground()!, forState: .normal)
        button.setBackgroundColor(color: R.color.blueButton()!, forState: .disabled)
        button.titleLabel?.font = R.font.poppinsMedium(size: 12)
        button.setTitleColor(R.color.secondaryBlack(), for: .normal)
        button.setTitleColor(.white, for: .disabled)
        button.addTarget(self, action: #selector(didTapFilter(button:)), for: .touchUpInside)
        button.cornerRadius = 15
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        return button
    }

    private func setupTagListView() {
        recentSearchesTagListView.delegate = self
    }
}

// MARK: Private functions

extension SearchViewController {

    private func handleStateChange(state: SearchViewModel.State) {
        if let error = state.lastError {
            self.handleError(error)
            return
        }
        for (index, button) in categoriesStackView.arrangedSubviews.compactMap({$0 as? UIButton}).enumerated() {
            button.isEnabled = SearchViewModel.SearchMode.allCases[index] != state.currentMode
        }
        searchTextField.text = state.currentQuery
        let dataCount: Int = {
            switch state.currentMode {
            case .posts:
                return state.foundPosts.count
            case .people:
                return state.foundPeople.count
            case .audio:
                return state.foundAudios.count
            }
        }()
        if dataCount == 0 {
            state.searching ? showLoading() : showEmptyView()
            resultsTableView.reloadData()
            return
        }
        showSearchResults()
    }

    private func showEmptyView() {
        guard viewModel.state.currentQuery.isEmpty else {
            emptyMessageLabel.text = R.string.localizable.searchNoResults()
            resultsTableView.backgroundView = emptyView
            return
        }
        if viewModel.state.recentSearches.count > 0 {
            recentSearchesTagListView.removeAllTags()
            recentSearchesTagListView.addTags(viewModel.state.recentSearches)
            resultsTableView.backgroundView = recentSearchesView
        } else {
            emptyMessageLabel.text = R.string.localizable.emptySearch(Configuration.appName)
            resultsTableView.backgroundView = emptyView
        }
    }

    private func showLoading() {
        resultsTableView.backgroundView = loadingView
    }

    private func showSearchResults() {
        resultsTableView.backgroundView = nil
        resultsTableView.reloadData()
    }

    @objc private func didTapFilter(button: UIButton) {
        if let index = categoriesStackView.arrangedSubviews.firstIndex(of: button) {
            viewModel.changeMode(SearchViewModel.SearchMode.allCases[index])
        }
        AudioPlayerService.shared.stop()
    }

    @objc private func search() {
        let text = searchTextField.text ?? ""
        viewModel.changeQuery(query: text)
    }
}

// MARK: - Navigation

extension SearchViewController {
    private func rowSelected(row: Int) {
        switch viewModel.state.currentMode {
        case .posts:
            let post = viewModel.state.foundPosts[row]
            MyPostsRouter(in: navigationController).openPostDetailsViewController(currentPost: post, profileDelegate: nil, postDelegate: self)
        case .people:
            let profile = viewModel.state.foundPeople[row]
            openProfile(id: profile.id, type: profile.type)
        case .audio:
            let audioTrack = viewModel.state.foundAudios[row]
            SearchRouter(in: navigationController).openAudioDetails(for: audioTrack)
            break
        }
    }

    private func openProfile(id: Int, type: ProfileType) {
        if id == ArchiveService.shared.currentProfile?.id {
            openMyProfile()
            return
        }
        switch type {
        case .basic:
            BasicProfileRouter(in: navigationController).openPublicProfileViewController(profileId: id)
        case .business:
            BusinessProfileRouter(in: navigationController).openPublicProfileController(id: id)
        }
    }

    private func openMyProfile() {
        MainScreenRouter(in: navigationController).openMyProfile()
    }

    private func openMessage(with profile: PostProfileModel) {
        ChatRouter(in: navigationController).opeChatDetailsViewController(with: profile.chatProfile)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension SearchViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        resultsCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch viewModel.state.currentMode {
        case .posts:
            let post = viewModel.state.foundPosts[indexPath.row]
            return postCell(post: post, in: tableView, at: indexPath)
        case .people:
            let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.searchProfileCell, for: indexPath)!
            cell.onMessageTap = { [weak self] profile in
                self?.openMessage(with: profile)
            }
            cell.profile = viewModel.state.foundPeople[indexPath.row]
            return cell
        case .audio:
            let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.audioSearchCell, for: indexPath)!
            cell.audioTrack = viewModel.state.foundAudios[indexPath.row]
            cell.delegate = self
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch viewModel.state.currentMode {
        case .posts, .audio:
            return UITableView.automaticDimension
        case .people:
            return 70
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let isLastRow: Bool = indexPath.row == resultsCount - 1
        if isLastRow {
            viewModel.search()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        rowSelected(row: indexPath.row)
    }

    private func postCell(post: PostModel, in tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        switch post.type {
        case .media:
            let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.mediaPostCell, for: indexPath)!
            cell.post = post
            cell.cellDelegate = self
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.postCell, for: indexPath)!
            cell.post = post
            cell.cellDelegate = self
            return cell
        }
    }

}

// MARK: - UITextFieldDelegate

extension SearchViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        search()
        return true
    }
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        viewModel.changeQuery(query: "")
        return true
    }

    @objc private func textFieldChanged() {
        if searchTextField.text!.isEmpty {
            viewModel.changeQuery(query: "")
        }
    }
}

// MARK: - TagListViewDelegate

extension SearchViewController: TagListViewDelegate {
    func tagPressed(_ title: String, tagView: TagView, sender: TagListView) {
        viewModel.changeQuery(query: title)
    }

    func tagRemoveButtonPressed(_ title: String, tagView: TagView, sender: TagListView) {
        viewModel.removeRecentQuery(query: title)
    }
}

// MARK: - PostCellDelegate

extension SearchViewController: PostCellDelegate {
    func reactionSelected(_ reaction: Reaction, for post: PostModel) {
        viewModel.addReaction(post: post, reaction: reaction)
    }

    func reactionRemoved(for post: PostModel) {
        viewModel.removeReaction(post: post)
    }

    func openMedia(_ media: MediaDataModel) {
        if media.type == .image {
            MyPostsRouter(in: self.navigationController).openImage(imageUrl: media.origin)
            return
        }
        if media.type == .video {
            MyPostsRouter(in: self.navigationController).openVideo(videoURL: media.origin)
        }
    }

    func reloadDescriptionLabel(post: PostModel) {
        UIView.performWithoutAnimation {
            resultsTableView.layoutIfNeeded()
            resultsTableView.beginUpdates()
            resultsTableView.endUpdates()
            resultsTableView.layer.removeAllAnimations()
        }
    }

    func followPost(_ post: PostModel) {
        viewModel.togglePostFollow(post: post)
    }

    func openProfile(post: PostModel) {
        guard let profile = post.profile else {
            return
        }
        openProfile(id: profile.id, type: profile.type)
    }

    func openReactions(post: PostModel) {
        BottomMenuPresentationManager.present(ReactionsListViewController(post: post), from: self)
    }

    func hashtagSelected(_ hashtag: String) {
        MyPostsRouter(in: navigationController).openHashtagPage(hashtag: hashtag)
    }

    func mentionSelected(profileId: Int) {
        profileNavigationResolver.openProfile(profileId: profileId)
    }

    func mediaViewed(media: MediaDataModel) {
        viewModel.viewMedia(media: media)
    }
}

// MARK: - MenuActionButtonDelegate

extension SearchViewController: MenuActionButtonDelegate {
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
                self.viewModel.togglePostFollow(post: post)
            case .delete:
                self.viewModel.deletePost(post: post)
            case .report:
                BasicProfileRouter(in: self.navigationController).openReportViewController(for: post)
            case .copy:
                self.copyDescription(post)
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
}

// MARK: - PostFormDelegate

extension SearchViewController: PostFormDelegate {
    func newPostAdded(post: PostModel) {}
    
    func postUpdated(post: PostModel) {
        viewModel.updatePost(post: post)
    }

    func postRemoved(post: PostModel) {
        viewModel.removePost(post: post)
    }
}

// MARK: - AudioTrackViewDelegate

extension SearchViewController: AudioTrackViewDelegate {
    func trackFavoriteToggled(track: AudioTrackModel) {
        viewModel.toggleAudioFollow(audioTrack: track)
    }

    func trackMorePressed(track: AudioTrackModel) {
        let controller = EntityMenuController(entity: track)
        controller.onMenuSelected = { [weak self] (type, post) in
            guard let self = self else {
                return
            }
            switch type {
            case .report:
                BasicProfileRouter(in: self.navigationController).openReportViewController(for: track)
            default:
                break
            }
        }
        present(controller.alertController, animated: true)
    }


}
