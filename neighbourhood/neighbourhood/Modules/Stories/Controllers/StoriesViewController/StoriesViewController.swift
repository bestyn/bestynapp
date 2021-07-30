//
//  StoriesViewController.swift
//  neighbourhood
//
//  Created by iphonovv on 30.11.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

private struct Constants {
    static let menuPoint: CGPoint = .init(x: 14, y: 51)
    static let menuSize: CGSize = .init(width: 259, height: 32)
    static let unauthVisibilityDuration: TimeInterval = 30
}

class StoriesViewController: BaseViewController {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet var pagingButtons: [DoubleBorderedButton]!
    @IBOutlet weak var pagingMenu: UIStackView!
    @IBOutlet weak var unauthView: UIView!

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private var isCommentsOpened = false
    private var isUserAuthorized: Bool { ArchiveService.shared.tokenModel != nil }
    private var unauthTimer: Timer?

    private lazy var orderedViewControllers: [UIViewController] = {
        let modes: [StoriesListViewModel.Mode] = isUserAuthorized ? [.all, .followed, .my] : [.all]
        return modes.map { (mode) -> UIViewController in
            let anchorStory: PostModel? = {
                if case .all = mode {
                    return ArchiveService.shared.lastVisitedStory
                }
                return nil
            }()
            let controller = StoriesListViewController(mode: mode, anchorStory: anchorStory)
            controller.delegate = self
            return controller
        }
    }()

    let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [:])

    var index: Int = 0 {
        didSet { updateActiveButton() }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        pagingMenu.isHidden = !isUserAuthorized
        setupPageViewController()
        updateActiveButton()

        NotificationCenter.default.addObserver(self, selector: #selector(handleBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleForeground), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isCommentsOpened {
            (self.parent as? MainViewController)?.hideMenu()
        }
    }

    @IBAction func didTapSearch(_ sender: Any) {
        checkAuthentication { [weak self] in
            guard let self = self else {
                return
            }
            SearchRouter(in: self.navigationController).openSearch()
        }
    }

    @IBAction func didTapAll(_ sender: Any) {
        if index == 0 {
            return
        }
        pageViewController.setViewControllers([orderedViewControllers[0]], direction: .reverse, animated: true)
        index = 0
    }

    @IBAction func didTapRecommended(_ sender: Any) {
        if index == 1 {
            return
        }
        pageViewController.setViewControllers([orderedViewControllers[1]], direction: index < 1 ? .forward : .reverse, animated: true)
        index = 1
    }

    @IBAction func didTapCreated(_ sender: Any) {
        if index == 2 {
            return
        }
        pageViewController.setViewControllers([orderedViewControllers[2]], direction: .forward, animated: true)
        index = 2
    }

    @IBAction func didTapSignIn(_ sender: Any) {
        AuthorizationRouter(in: navigationController).openSignInScreen()
    }

    @IBAction func didTapSignUp(_ sender: Any) {
        RegistrationRouter(in: navigationController).openSignUpScreen()
    }
}

// MARK: - Private methods

extension StoriesViewController {
    @objc private func handleBackground() {
        (pageViewController.viewControllers?.first as? StoriesListViewController)?.pauseAll()
    }

    @objc private func handleForeground() {
        guard viewIfLoaded?.window != nil else {
            return
        }
        (pageViewController.viewControllers?.first as? StoriesListViewController)?.playCurrent()
    }
}

// MARK: - Configuration

extension StoriesViewController {

    private func setupPageViewController() {
        containerView.addSubview(pageViewController.view)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
        addChild(pageViewController)
        pageViewController.didMove(toParent: self)

        pageViewController.delegate = self
        pageViewController.dataSource = self

        if let firstViewController = orderedViewControllers.first {
            pageViewController.setViewControllers([firstViewController],
                                                  direction: .forward,
                                                  animated: false,
                                                  completion: nil)
        }
    }

    private func updateActiveButton() {
        for (index, button) in pagingButtons.enumerated() {
            button.innerBorderColor = index == self.index ? UIColor.white.withAlphaComponent(0.6) : .clear
            button.outerBorderColor = index == self.index ? UIColor.black.withAlphaComponent(0.2) : .clear
            button.setNeedsLayout()
        }
    }

    public func checkAuthentication(onAuth: () -> Void, onUnauth: (() -> Void)? = nil) {
        guard ArchiveService.shared.tokenModel == nil else {
             onAuth()
            return
        }
        shouldAuth()
        onUnauth?()
    }

    private func shouldAuth() {
        unauthTimer?.invalidate()
        unauthView.alpha = 0
        unauthView.isHidden = false
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.unauthView.alpha = 1
        }
        unauthTimer = Timer.scheduledTimer(withTimeInterval: Constants.unauthVisibilityDuration, repeats: false) { (timer) in
            UIView.animate(withDuration: 0.3) { [weak self] in
                self?.unauthView.alpha = 0
            } completion: { [weak self] (_) in
                self?.unauthView.isHidden = true
            }
        }
    }
}

// MARK: - UIPageViewControllerDelegate

extension StoriesViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    // MARK: - UIPageViewControllerDataSource
    
    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.lastIndex(of:viewController) else {
            return nil
        }
        self.index = viewControllerIndex
        let nextIndex = viewControllerIndex + 1
        let orderedViewControllersCount = orderedViewControllers.count
        guard orderedViewControllersCount != nextIndex else {
            return nil
        }
        guard orderedViewControllersCount > nextIndex else {
            return nil
        }
        return orderedViewControllers[nextIndex]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.lastIndex(of: viewController) else {
            return nil
        }
        self.index = viewControllerIndex
        let previousIndex = viewControllerIndex - 1
        guard previousIndex >= 0 else {
            return nil
        }
        guard orderedViewControllers.count > previousIndex else {
            return nil
        }
        return orderedViewControllers[previousIndex]
    }
}

// MARK: - StoriesListViewControllerDelegate

extension StoriesViewController: StoriesListViewControllerDelegate {
    func isUserAuthorized(completion: @escaping (Bool) -> Void) {
        checkAuthentication {
            completion(true)
        } onUnauth: {
            completion(false)
        }

    }

    func commentsViewShown() {
        pageViewController.view.isUserInteractionEnabled = false
        (parent as? MainViewController)?.hideMenu()
        isCommentsOpened = true
    }

    func commentsViewHidden() {
        pageViewController.view.isUserInteractionEnabled = true
        isCommentsOpened = false
        (parent as? MainViewController)?.showMenu()
    }

    func commentsPresenterViewController() -> UIViewController {
        self
    }
}
