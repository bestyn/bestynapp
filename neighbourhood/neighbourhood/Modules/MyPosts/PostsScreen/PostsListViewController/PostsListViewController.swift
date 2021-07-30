//
//  PostsListViewController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 26.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import GBKSoftRestManager

private enum Defaults {
    static let topGap: CGFloat = 92
}

enum PostsListMode {
    case followedPosts
    case myPosts
}

protocol PostListScrollDelegate: class {
    func listScrollDidBegin(scrollView: UIScrollView)
    func listScrollDidEnd(scrollView: UIScrollView, decelerate: Bool)
    func listDidScroll(scrollView: UIScrollView)
}

final class PostsListViewController: BasePostListViewController {

    private let mode: PostsListMode

    public weak var scrollDelegate: PostListScrollDelegate?
    
    init(mode: PostsListMode) {
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(onTabChanged(notification:)), name: .tabbarUpdated, object: nil)
        tableView.contentInset = UIEdgeInsets(top: Defaults.topGap, left: 0, bottom: 0, right: 0)
        if mode == .myPosts {
            NotificationCenter.default.addObserver(self, selector: #selector(postCreated), name: .postCreated, object: nil)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        switch mode {
        case .followedPosts:
            AnalyticsService.logOpenFollowedPosts()
        case .myPosts:
            AnalyticsService.logOpenCreatedPosts()
        }
    }

    override var emptyViewTitle: String {
        searchPostsByString.count > 0
            ?  R.string.localizable.noChatMatches()
            : filters.count > 0
            ? R.string.localizable.emptyPostState()
            :  R.string.localizable.noPostsYet()
    }

    override func fetchPosts() -> PreparedOperation<[PostModel]> {
        switch mode {
        case .followedPosts:
            return postsManager.getMyPost(search: searchPostsByString, types: filters, authorMe: 0, page: nextPage)
        case .myPosts:
            return postsManager.getMyPost(search: searchPostsByString, types: filters, page: nextPage)
        }
    }

    override func postFollowChanged(post: PostModel) {
        if post.iFollow,
            mode == .followedPosts {
            removePost(post)
            return
        }
        super.postFollowChanged(post: post)
    }

    @objc func onTabChanged(notification: Notification) {
        if let index = notification.object as? Int,
           index == 1 {
            refreshPostsList()
        }
    }

    @objc private func postCreated() {
        self.refreshPostsList()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollDelegate?.listDidScroll(scrollView: scrollView)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollDelegate?.listScrollDidBegin(scrollView: scrollView)
        for cell in tableView.visibleCells  {
            (cell as? PostCell)?.pauseVideo()
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollDelegate?.listScrollDidEnd(scrollView: scrollView, decelerate: decelerate)
        if decelerate {
            return
        }
        playFirstVisibleVideo()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        playFirstVisibleVideo()
    }

    private func playFirstVisibleVideo() {
        for cell in tableView.visibleCells {
            guard let postCell = cell as? PostCell else {
                continue
            }
            if postCell.hasVideo() {
                postCell.playVideo()
                break
            }
        }
    }
}


