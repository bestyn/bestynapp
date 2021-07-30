//
//  MainViewController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 08.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

class MainViewController: BaseViewController {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var floatingMenuView: FloatingMenuView!

    private lazy var homeController = HomeListViewController()
    private lazy var myPostsController = MyPostsViewController()
    private lazy var chatController = ChatsListViewController()
    private lazy var neighbourgsController = MyNeighborsViewController()
    private lazy var storiesController = StoriesViewController()

    private lazy var authorizationManager: RestAuthorizationManager = RestService.shared.createOperationsManager(from: self)

    override var preferredStatusBarStyle: UIStatusBarStyle {
        children.first?.preferredStatusBarStyle ?? .default
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        floatingMenuView.delegate = self
        FloatingMenuView.selectedItem = .stories
        setActiveController(storiesController)
        setupObservers()
        setupRealtimeListeners()
    }

    private func setActiveController(_ controller: UIViewController) {
        showMenu()
        if let currentController = children.first {
            currentController.removeFromParent()
            currentController.view.removeFromSuperview()
        }
        self.addChild(controller)
        containerView.addSubview(controller.view)
        controller.view.frame = containerView.bounds
        controller.didMove(toParent: self)
    }

    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(profileChanged), name: .profileDidChanged, object: nil)
    }

    func setupRealtimeListeners() {
        guard let currentUserId = ArchiveService.shared.userModel?.id else {
            return
        }

        RealtimeService.shared.listen(channel: RealtimeService.Channel.userNotifications(userID: currentUserId)) { (message) in
            guard let chatMessageModel = message.model(of: RealtimePrivateChatUpdateModel.self) else {
                    return
            }
            if let extraData = chatMessageModel.extraData {
                ChatUnreadMessageService.shared.update(profileId: chatMessageModel.data.recipientProfileId,
                                                   hasUnreadMessages: extraData.hasUnreadMessages)
            }
        }
    }

    @objc private func profileChanged() {
        guard let currentController = children.first,
              let currentProfile = ArchiveService.shared.currentProfile else {
            return
        }
        if !(currentController is ProfileViewController || currentController is MyBusinessViewController) {
            return
        }
        if currentProfile.type == .basic, currentController is ProfileViewController {
            return
        }
        if let businesController = currentController as? MyBusinessViewController,
           businesController.currentProfileId == currentProfile.id {
            return
        }
        openMyProfile()
    }

    func openHomeFeed() {
        FloatingMenuView.selectedItem = .home
        floatingMenuView.didItemChanged(item: .home)
        setActiveController(homeController)
    }
}

extension MainViewController {
    public func hideMenu() {
        floatingMenuView.isHidden = true
    }

    public func showMenu() {
        floatingMenuView.isHidden = false
    }
}

// MARK: - FloatingMenuViewDelegate

extension MainViewController: FloatingMenuViewDelegate {
    func didSelectedMenuItem(_ item: FloatingMenuItem) {
        switch item {
        case .profile:
            BottomMenuPresentationManager.present(ProfileSwitcherViewController(delegate: self), from: self)
        case .addPost:
            if PostSaver.shared.checkPostFormAvailability(),
               RecordVoiceViewModel.shared.checkVoiceRecording() {
                BottomMenuPresentationManager.present(PostTypeSelectorViewController(delegate: self), from: self)
            }
        case .neighbourgs:
            setActiveController(neighbourgsController)
            FloatingMenuView.selectedItem = .neighbourgs
        case .chats:
            setActiveController(chatController)
            FloatingMenuView.selectedItem = .chats
        case .home:
            if let currentController = children.first,
               currentController == homeController {
                homeController.scrollToBegin()
            } else {
                setActiveController(homeController)
            }
            FloatingMenuView.selectedItem = .home
        case .more:
            BottomMenuPresentationManager.present(MoreActionsViewController(delegate: self), from: self)
            break
        case .stories:
            FloatingMenuView.selectedItem = .stories
            setActiveController(storiesController)
        case .bestyn:
            setActiveController(homeController)
        }
    }

    func canChangeMenuItem(_ item: FloatingMenuItem, completion: @escaping (Bool) -> Void) {
        if let currentController = children.first,
           currentController == storiesController {
            storiesController.checkAuthentication {
                completion(true)
            } onUnauth: {
                completion(false)
            }
            return
        }
        completion(true)
    }
}

// MARK: - AccountSwitcherDelegate

extension MainViewController: AccountSwitcherDelegate {
    func openAddBusinessProfile() {
        BusinessProfileRouter(in: navigationController).openAddBusinessProfile()
    }

    func openMyProfile() {
        guard let currentProfile = ArchiveService.shared.currentProfile else {
            return
        }
        switch currentProfile.type {
        case .basic:
            setActiveController(ProfileViewController())
        case .business:
            if !(children.first is MyBusinessViewController) {
                setActiveController(MyBusinessViewController())
            }
        }
        FloatingMenuView.selectedItem = .profile
        floatingMenuView.didItemChanged(item: .profile)
    }
}

// MARK: - MoreActionsDelegate

extension MainViewController: MoreActionsDelegate {
    func moreActionSelected(action: MoreAction) {
        switch action {
        case .settings:
            if let currentProfile = ArchiveService.shared.currentProfile {
                switch currentProfile.type {
                case .basic:
                    BasicProfileRouter(in: navigationController).openProfileSettingsViewController()
                case .business:
                    if let businessProfile = ArchiveService.shared.userModel?.businessProfiles?.first(where: {$0.id == currentProfile.id}) {
                        BusinessProfileRouter(in: navigationController).openEditBusinessProfile(profile: businessProfile)
                    }
                }
            }
        case .payments:
            BusinessProfileRouter(in: navigationController).openPaymentPlansViewController()
        case .about:
            if let url = URL(string: "https://bestyn.app/"),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        case .privacy:
            SupportRouter(in: navigationController).openPage(type: .policy)
        case .terms:
            SupportRouter(in: navigationController).openPage(type: .terms)
        case .logout:
            Alert(title: Alert.Title.signOut, message: Alert.Message.signOut)
                .configure(doneText: Alert.Action.signOut)
                .configure(cancelText: Alert.Action.cancel)
                .show { (result) in
                    if result == .done {
                        self.restSignOut()
                    }
                }
        }
    }
}

// MARK: - PostSelectorDelegate

extension MainViewController: PostSelectorDelegate {
    func postTypeDidSelected(_ type: TypeOfPost) {
        let delegate = children.first as? BasePostListViewController
        BasicProfileRouter(in: navigationController).openCreatePost(of: type, delegate: delegate)
    }
}

// MARK: - REST requests

extension MainViewController {
    func restSignOut() {
        guard ValidationManager().checkInternetConnection() else {
            Toast.show(message: R.string.localizable.internetConnectionError())
            return
        }

        authorizationManager.signOut()
            .onError { (error) in
                self.handleError(error)
            }
            .onComplete { _ in
                ArchiveService.shared.currentProfile = nil
                RootRouter.shared.exitApp()
            } .run()
    }
}
