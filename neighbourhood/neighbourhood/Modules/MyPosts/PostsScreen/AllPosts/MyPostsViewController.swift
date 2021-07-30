//
//  MyPostsViewController.swift
//  neighbourhood
//
//  Created by Dioksa on 24.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

private enum Defaults {
    static let topGap: CGFloat = 92
}

final class MyPostsViewController: BaseViewController {
    @IBOutlet private weak var tagsCollectionView: UICollectionView!
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var followedPostsButton: UIButton!
    @IBOutlet private weak var myPostsButton: UIButton!
    @IBOutlet private weak var followBottomView: UIView!
    @IBOutlet private weak var createdBottomView: UIView!
    @IBOutlet weak var topBarView: UIView!

    private let pageController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    private lazy var followedPostsController: PostsListViewController = {
        let controller = PostsListViewController(mode: .followedPosts)
        controller.scrollDelegate = self
        return controller
    }()
    private lazy var myPostsController: PostsListViewController = {
        let controller = PostsListViewController(mode: .myPosts)
        controller.scrollDelegate = self
        return controller
    }()
    private lazy var profileManager: RestProfileManager = RestService.shared.createOperationsManager(from: self, type: RestProfileManager.self)
    private lazy var businessManager: RestBusinessProfileManager = RestService.shared.createOperationsManager(from: self, type: RestBusinessProfileManager.self)
    private var lastContentOffset: CGPoint = .zero

    private var filterArray: [TypeOfPost] {
         [
            TypeOfPost.general,
            TypeOfPost.news,
            TypeOfPost.crime,
            TypeOfPost.event,
            TypeOfPost.media,
            TypeOfPost.offer
        ]
    }


    private var currentListController: PostsListViewController? {
        pageController.viewControllers?.first as? PostsListViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPageViewController()
        setupTopBarView()
        tagsCollectionView.register(R.nib.filterItemCollectionCell)
        tagsCollectionView.register(R.nib.searchCell)
        configureColors()
        
        if let viewLayout = tagsCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            viewLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        }
        
        if let currentListController = pageController.viewControllers?.first as? PostsListViewController, currentListController.filters.isEmpty {
            tagsCollectionView.indexPathsForSelectedItems?.filter({ $0.row != 0 }).forEach({ tagsCollectionView.deselectItem(at: $0, animated: true) })
            tagsCollectionView.selectItem(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .left)
        }

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(profileChanged), name: .profileDidChanged, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        tagsCollectionView.reloadData()
        tagsCollectionView.setNeedsLayout()
    }

    private func setupTopBarView() {
        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        topBarView.insertSubview(blurView, at: 0)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blurView.heightAnchor.constraint(equalTo: topBarView.heightAnchor),
            blurView.widthAnchor.constraint(equalTo: topBarView.widthAnchor)
        ])
        topBarView.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 16)
    }
    
    private func setupPageViewController() {
        addChild(pageController)
        containerView.addSubview(pageController.view)
        pageController.view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addConstraints([
            pageController.view.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 0),
            pageController.view.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 0),
            pageController.view.rightAnchor.constraint(equalTo: containerView.rightAnchor, constant: 0),
            pageController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 0)
        ])
        
        pageController.didMove(toParent: self)
        pageController.dataSource = self
        pageController.delegate = self
        pageController.setViewControllers([followedPostsController], direction: .forward, animated: false, completion: nil)
        updateButtonState()
    }
    
    // MARK: - Private actions
    @IBAction private func didTapFollowedPosts(_ sender: Any) {
        pageController.setViewControllers([followedPostsController], direction: .reverse, animated: true, completion: nil)
        updateButtonState()
        updateFiltersState()
        followedPostsController.searchPostsByString = ""
        followedPostsController.refreshPostsList()
    }
    
    @IBAction private func didTapMyPosts(_ sender: Any) {
        pageController.setViewControllers([myPostsController], direction: .forward, animated: true, completion: nil)
        updateButtonState()
        updateFiltersState()
        myPostsController.searchPostsByString = ""
        myPostsController.refreshPostsList()
    }
    
    @objc private func profileChanged() {
        UIView.animate(withDuration: 0.1) {
            self.topBarView.transform = .identity
            self.topBarView.backgroundColor = .white
        }
        updateFiltersState()
        currentListController?.refreshPostsList()
    }
}

// MARK: - UI configurations
private extension MyPostsViewController {

    func updateButtonState() {
        followedPostsButton.isEnabled = pageController.viewControllers?.first != followedPostsController
        myPostsButton.isEnabled = pageController.viewControllers?.first != myPostsController
        
        defineButtonColorForState(button: followedPostsButton, bottomView: followBottomView)
        defineButtonColorForState(button: myPostsButton, bottomView: createdBottomView)
    }
    
    func defineButtonColorForState(button: UIButton, bottomView: UIView) {
        if !button.isEnabled {
            button.setTitleColor(R.color.blueButton(), for: .normal)
            bottomView.backgroundColor = R.color.blueButton()
        } else {
            button.setTitleColor(R.color.greyMedium(), for: .normal)
            bottomView.backgroundColor = R.color.greyBackground()
        }
    }
    
    func configureColors() {
        followedPostsButton.setTitleColor(R.color.blueButton(), for: .normal)
        myPostsButton.setTitleColor(R.color.greyMedium(), for: .normal)
        followBottomView.backgroundColor = R.color.blueButton()
        createdBottomView.backgroundColor = R.color.greyBackground()
    }

    private func resetTopBarPosition() {
        UIView.animate(withDuration: 0.1) {
            self.topBarView.transform = .identity
            self.topBarView.backgroundColor = .white
        }
    }
}

// MARK: - Filter actions
private extension MyPostsViewController {
    func updateFiltersState() {
        currentListController?.filters = []
        tagsCollectionView.indexPathsForSelectedItems?.filter({ $0.row != 1 }).forEach({ tagsCollectionView.deselectItem(at: $0, animated: true) })
        tagsCollectionView.selectItem(at: IndexPath(row: 1, section: 0), animated: true, scrollPosition: .centeredHorizontally)
    }
}

// MARK: - UIPageViewControllerDataSource, UIPageViewControllerDelegate
extension MyPostsViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if viewController == myPostsController {
            return followedPostsController
        }
        
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if viewController == followedPostsController {
            return myPostsController
        }
        
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        updateButtonState()
        updateFiltersState()
        resetTopBarPosition()
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension MyPostsViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filterArray.count + 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == 0 {
            return collectionView.dequeueReusableCell(withReuseIdentifier: R.nib.searchCell, for: indexPath)!
        }
        let title: String = {
            switch indexPath.row {
            case 1:
                return R.string.localizable.allFilter()
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
            currentListController?.filters = []
        default:
            let selectedFilter = filterArray[indexPath.row - 2]
            currentListController?.filters = [selectedFilter]
        }
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if indexPath.row == 0 {
            SearchRouter(in: navigationController).openSearch()
            return false
        }
        return true
    }
}

// MARK: - PostListScrollDelegate

extension MyPostsViewController: PostListScrollDelegate {
    func listScrollDidBegin(scrollView: UIScrollView) {
        guard scrollView.contentOffset.y > 0,
              scrollView.contentOffset.y < scrollView.contentSize.height else {
            return
        }
        lastContentOffset = scrollView.contentOffset
    }

    func listScrollDidEnd(scrollView: UIScrollView, decelerate: Bool) {
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

    func listDidScroll(scrollView: UIScrollView) {
        guard scrollView.contentOffset.y > 0,
              scrollView.contentOffset.y + scrollView.bounds.height < scrollView.contentSize.height else {
            return
        }
        let move = scrollView.contentOffset.y - lastContentOffset.y
        lastContentOffset = scrollView.contentOffset
        if move > 0 {
            topBarView.transform = CGAffineTransform(translationX: 0, y: max(-topBarView.frame.height, topBarView.frame.minY - move))
        } else {
            topBarView.transform = CGAffineTransform(translationX: 0, y: min(topBarView.frame.minY - move, 0))
        }
        let alpha = min(1, max(0, 1 - scrollView.contentOffset.y / Defaults.topGap))
        topBarView.backgroundColor = UIColor.white.withAlphaComponent(alpha)
    }


}
