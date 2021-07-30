//
//  HomeListViewController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 26.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import GBKSoftRestManager

enum HomeListMode {
    case all, recommended, my, followed, onlyBusiness
}

private enum Defaults {
    static let topGap: CGFloat = 50 
}

final class HomeListViewController: BasePostListViewController {
    
    @IBOutlet weak var topBarView: UIView!
    @IBOutlet weak var filterCollectionView: UICollectionView!
    @IBOutlet weak var activeRecordIndicatorView: UIView!
    @IBOutlet weak var activeRecordButton: UIButton!

    private var headerView: NewsHeaderView!
    
    private var newsData: Items<NewsModel> = .init()
    private var justOpen = true
    private var selectedFilter = IndexPath(row: 1, section: 0)

    private lazy var recordAnimationCircles: [UIView] = {
        var circles: [UIView] = []
        for _ in 0..<2 {
            let circle = UIView()
            activeRecordIndicatorView.insertSubview(circle, at: 0)
            circle.translatesAutoresizingMaskIntoConstraints = false
            circle.heightAnchor.constraint(equalToConstant: 30).isActive = true
            circle.widthAnchor.constraint(equalToConstant: 30).isActive = true
            circle.centerXAnchor.constraint(equalTo: activeRecordIndicatorView.centerXAnchor).isActive = true
            circle.centerYAnchor.constraint(equalTo: activeRecordIndicatorView.centerYAnchor).isActive = true
            circle.cornerRadius = 15
            circle.backgroundColor = R.color.accentRed()?.withAlphaComponent(0.2)
            circles.append(circle)
            circle.isUserInteractionEnabled = false
        }
        return circles
    }()
    
    private lazy var newsFeedManager: RestNewsFeedManager = RestService.shared.createOperationsManager(from: self, type: RestNewsFeedManager.self)
    
    private var filterArray: [TypeOfPost] {
        let filters = [
            TypeOfPost.general,
            TypeOfPost.news,
            TypeOfPost.crime,
            TypeOfPost.event,
            TypeOfPost.offer,
            TypeOfPost.media
        ]

        return filters
    }

    private var otherModes: [(String, HomeListMode)] {
        var modes: [(String, HomeListMode)] = [
            (R.string.localizable.forYouFilter(), .recommended)
        ]
        if ArchiveService.shared.currentProfile?.type == .business ||
            ArchiveService.shared.seeBusinessContent {
            modes.append((R.string.localizable.businessFilter(), .onlyBusiness))
        }
        modes.append(contentsOf: [
            (R.string.localizable.createdFilter(), .my),
            (R.string.localizable.followedFilter(), .followed)
        ])
        return modes
    }

    private var isNewsFeedVisible: Bool {
        guard [.all, .recommended].contains(mode) else {
            return false
        }
        if newsData.items.count == 0 {
            return false
        }
        if posts.count > 0 {
            return true
        }
        if ArchiveService.shared.interestExist == false,
           ArchiveService.shared.currentProfile?.type == .basic,
           mode == .recommended {
            return false
        }
        if filters.count > 0 || !searchPostsByString.isEmpty {
            return false
        }
        return true
    }
    
    private var lastContentOffset: CGPoint = .zero
    
    private var mode: HomeListMode = .all
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.contentInset = UIEdgeInsets(top: Defaults.topGap, left: 0, bottom: 0, right: 0)
        configureNewsTableHeader()
        setupTopBarView()
        setupFilters()
        emptyView.delegate = self
        fetchNewsFeed()
        NotificationCenter.default.addObserver(self, selector: #selector(profileChanged), name: .profileDidChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(postCreated), name: .postCreated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(postUpdated(notification:)), name: .postUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(postRemoved(notification:)), name: .postRemoved, object: nil)
        RecordVoiceViewModel.shared.$recordState.bind { [weak self] (state) in
            self?.handleRecordState(state)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        filterCollectionView.reloadData()
        filterCollectionView.setNeedsLayout()
        filterCollectionView.selectItem(at: selectedFilter, animated: false, scrollPosition: .centeredVertically)
        handleRecordState(RecordVoiceViewModel.shared.recordState)
        playFirstVisibleVideo()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pauseAll()
    }

    public func scrollToBegin() {
        tableView.scrollToTop()
    }
    
    override var emptyViewTitle: String {
        return R.string.localizable.emptyPostState()
    }
    
    override func fetchPosts() -> PreparedOperation<[PostModel]> {
        switch mode {
        case .all:
            return postsManager.getLocalPosts(
                postTypes: filters,
                page: nextPage)
        case .onlyBusiness:
            return postsManager.getLocalPosts(
                postTypes: [],
                onlyBusinessPosts: true,
                page: nextPage)
        case .recommended:
            return postsManager.getLocalPosts(
                postTypes: [],
                withinMyInterests: true,
                page: nextPage)
        case .my:
            return postsManager.getMyPost(search: searchPostsByString, types: [], page: nextPage)
        case .followed:
            return postsManager.getMyPost(search: searchPostsByString, types: [], authorMe: 0, page: nextPage)
        }
    }

    override func postFollowChanged(post: PostModel) {
        if post.iFollow,
            mode == .followed {
            removePost(post)
        }
        super.postFollowChanged(post: post)
    }
    
    private func configureNewsTableHeader() {
        tableView.register(UINib(resource: R.nib.newsHeaderView), forHeaderFooterViewReuseIdentifier: NewsHeaderView.reuseIdentifier)
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: CGFloat.leastNormalMagnitude))
    }
    
    private func setupTopBarView() {
        topBarView.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 16)
    }
    
    private func setupFilters() {
        filterCollectionView.register(R.nib.filterItemCollectionCell)
        filterCollectionView.register(R.nib.searchCell)
        if let viewLayout = filterCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            viewLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        }
    }

    override func shouldReplace(post: PostModel) -> Bool {
        if mode == .followed, !post.iFollow {
            return false
        }
        return true
    }
    
    override func updateEmptyViewState() {
        if newsData.isLoading || loadingPosts {
            return
        }
        if posts.count > 0 {
            emptyView.isHidden = true
            return
        }
        
        if !filters.isEmpty || !searchPostsByString.isEmpty {
            emptyView.isHidden = false
            emptyView.setAttributesForEmptyScreen(text: R.string.localizable.emptyPostState())
            return
        }
        
        if ArchiveService.shared.interestExist == false,
           ArchiveService.shared.currentProfile?.type == .basic,
           mode == .recommended {
            emptyView.isHidden = false
            emptyView.setAttributesForEmptyScreen(
                text: R.string.localizable.provideInterests(),
                isButtonVisible: true)
            return
        }

        if newsData.items.count > 0 &&  filters.count == 0 && searchPostsByString.isEmpty && [.all, .recommended].contains(mode) {
            emptyView.isHidden = true
            return
        }
        
        emptyView.isHidden = false
        emptyView.setAttributesForEmptyScreen(text: R.string.localizable.noPostsYet())
        return
    }
    
    @objc override func refreshPostsList() {
        super.refreshPostsList()
        newsData = .init()
        fetchNewsFeed()
    }
    
    @objc func profileChanged() {
        UIView.animate(withDuration: 0.1) {
            self.topBarView.transform = .identity
            self.topBarView.backgroundColor = .white
        }
        refreshPostsList()
        filterCollectionView.reloadData()
        filterCollectionView.setNeedsLayout()
    }

    @objc private func postCreated() {
        self.refreshPostsList()
    }

    @objc private func postUpdated(notification: Notification) {
        if let post = notification.object as? PostModel {
            postUpdated(post: post)
        }
    }

    @objc private func postRemoved(notification: Notification) {
        if let post = notification.object as? PostModel {
            postRemoved(post: post)
        }
    }

    private func handleRecordState(_ state: RecordVoiceViewModel.State) {
        switch state {
        case .recording:
            startRecordAnimation()
            activeRecordIndicatorView.isHidden = false
            activeRecordButton.tintColor = R.color.accentRed()
            activeRecordButton.borderColor = R.color.accentRed()?.withAlphaComponent(0.2)
        case .recorded:
            stopRecordAnimation()
            activeRecordIndicatorView.isHidden = false
            activeRecordButton.tintColor = R.color.accent3()
            activeRecordButton.borderColor = R.color.accent3()?.withAlphaComponent(0.2)
        default:
            activeRecordIndicatorView.isHidden = true
            stopRecordAnimation()
        }
    }

    private func startRecordAnimation() {
        guard recordAnimationCircles.count > 0 else {
            return
        }
        recordAnimationCircles.forEach({ circle in
            circle.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            circle.alpha = 1
            circle.layer.removeAllAnimations()
        })
        let duration = 2.0
        let delay = 0.5
        for (index, circle) in recordAnimationCircles.enumerated() {
            UIView.animate(withDuration: duration, delay: delay * Double(index), options: [.repeat], animations: {
                circle.transform = CGAffineTransform(scaleX: 1.9, y: 1.9)
                    circle.alpha = 0
                }, completion: { _ in
                    circle.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                    circle.alpha = 1
                })
        }
    }

    private func stopRecordAnimation() {
        recordAnimationCircles.forEach({ circle in
            circle.layer.removeAllAnimations()
            circle.transform = .identity
            circle.alpha = 0
        })
    }
    
    // MARK: - REST requests
    private func fetchNewsFeed() {
        guard !newsData.isLoading else {
            return
        }
        newsFeedManager.getNewsFeed(page: newsData.nextPage)
            .onStateChanged { [weak self] (state) in
                guard let self = self else {
                    return
                }
                switch state {
                case .started:
                    self.newsData.isLoading = true
                    self.refreshControl.beginRefreshing()
                case .ended:
                    if !self.loadingPosts {
                        self.refreshControl.endRefreshing()
                    }
                    self.newsData.isLoading = false
                    self.updateEmptyViewState()
                }
            }
            .onError { [weak self] (error) in
                self?.handleError(error)
            }.onComplete { [weak self] (model) in
                guard let self = self  else { return }
                
                self.newsData.pagination = model.pagination
                if self.newsData.items.count == 0 {
                    self.newsData.items.append(contentsOf: model.result ?? [])
                    self.tableView.reloadData()
                } else {
                    self.newsData.items.append(contentsOf: model.result ?? [])
                    self.headerView?.items = self.newsData.items
                }
            }.run()
    }
    
    private func loadMoreNews() {
        guard newsData.canNextPage else {
            return
        }
        
        fetchNewsFeed()
    }


    @IBAction func didTapRecordIndicator(_ sender: Any) {
        MyPostsRouter(in: navigationController).returnToVoiceRecord()
    }

}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension HomeListViewController {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard isNewsFeedVisible else {
            return nil
        }
        headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: NewsHeaderView.reuseIdentifier) as! NewsHeaderView
        headerView.items = newsData.items
        headerView.delegate = self
        headerView.collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .left, animated: true)
        headerView.contentView.backgroundColor = R.color.greyBackground()
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        UIView.animate(withDuration: 0.1) {
            self.topBarView.transform = .identity
            self.topBarView.backgroundColor = .white
        }
        guard isNewsFeedVisible else {
            return 0
        }
        return NewsHeaderView.height
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView is UITableView else {
            return
        }
        playFirstVisibleVideo()

        guard scrollView.contentOffset.y > 0,
              scrollView.contentOffset.y + scrollView.bounds.height < scrollView.contentSize.height,
              !refreshControl.isRefreshing else {
            return
        }
        let move = scrollView.contentOffset.y - lastContentOffset.y
        lastContentOffset = scrollView.contentOffset
        if move > 0 {
            topBarView.transform = CGAffineTransform(translationX: 0, y: max(-topBarView.frame.height, topBarView.frame.minY - move))
        } else {
            topBarView.transform = CGAffineTransform(translationX: 0, y: min(topBarView.frame.minY - move, 0))
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard scrollView is UITableView,
              scrollView.contentOffset.y > 0,
              scrollView.contentOffset.y < scrollView.contentSize.height else {
            return
        }
        lastContentOffset = scrollView.contentOffset
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView is UITableView else {
            return
        }
        if decelerate {
            return
        }
        let translation = scrollView.panGestureRecognizer.translation(in: scrollView).y
        if translation > 0, topBarView.frame.minY < 0 {
            UIView.animate(withDuration: 0.1) {
                self.topBarView.transform = .identity
            }
            return
        }
        if translation < 0, topBarView.frame.maxY > 0 {
            UIView.animate(withDuration: 0.1) {
                self.topBarView.transform = CGAffineTransform(translationX: 0, y: -self.topBarView.frame.height)
            }
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        playFirstVisibleVideo()
    }

    private func playFirstVisibleVideo() {
        var isPlaying = false
        for cell in tableView.visibleCells {
            guard let postCell = cell as? PostCell else {
                continue
            }
            if !isPlaying,
               postCell.hasVideo(),
               postCell.frame.midY > tableView.contentOffset.y,
               postCell.frame.midY < tableView.contentOffset.y + tableView.bounds.height {
                postCell.playVideo()
                isPlaying = true
            } else {
                postCell.pauseVideo()
            }
        }
    }

    private func pauseAll() {
        tableView.visibleCells.compactMap({$0 as? PostCell}).forEach({$0.pauseVideo()})
    }
}

// MARK: - NewsHeaderViewDelegate
extension HomeListViewController: NewsHeaderViewDelegate {
    func newsHeaderViewDidLoadMore() {
        loadMoreNews()
    }
}

// MARK: - EmptyViewActionDelegate
extension HomeListViewController: EmptyViewActionDelegate {
    func openInterestsScreen() {
        profileManager.getUser()
            .onComplete { [weak self] (result) in
                if let user = result.result {
                    ArchiveService.shared.userModel = user
                    ArchiveService.shared.seeBusinessContent = user.profile.seeBusinessPosts
                    BasicProfileRouter(in: self?.navigationController).openMyInterestsViewController(type: .create)
                }
            } .onError { (error) in
                Toast.show(message: Alert.ErrorMessage.serverUnavailable)
                switch error {
                case .unauthorized:
                    RootRouter.shared.exitApp()
                default:
                    break
                }
            } .run()
    }
}

// MARK: - UICollectionViewDelegateFlowLayout, UICollectionViewDataSource

extension HomeListViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filterArray.count + otherModes.count + 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == 0 {
            return collectionView.dequeueReusableCell(withReuseIdentifier: R.nib.searchCell, for: indexPath)!
        }
        let title: String = {
            switch indexPath.row {
            case 1:
                return R.string.localizable.allFilter()
            case _ where indexPath.row >= filterArray.count + 2:
                return otherModes[indexPath.row - filterArray.count - 2].0
            default:
                return filterArray[indexPath.row - 2].filterTitle
            }
        }()
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.nib.filterItemCollectionCell, for: indexPath)!
        cell.setFilterTitle(title)
        cell.setNeedsLayout()
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        switch indexPath.row {
        case 0:
            return
        case 1:
            mode = .all
            filters = []
        case _ where indexPath.row >= filterArray.count + 2:
            mode = otherModes[indexPath.row - filterArray.count - 2].1
            filters = []
        default:
            mode = .all
            let selectedFilter = filterArray[indexPath.row - 2]
            filters = [selectedFilter]
        }
        selectedFilter = indexPath
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if indexPath.row == 0 {
            SearchRouter(in: navigationController).openSearch()
            return false
        }
        return true
    }
}
