//
//  RootRouter.swift
//  neighbourhood
//
//  Created by Dioksa on 21.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

class RootRouter {
    
    static let shared = RootRouter()
    private init() {}
    private(set) var isMaintanance = false
    
    let rootNavigationController = UINavigationController()
    
    private var window: UIWindow!
    private lazy var profileManager: RestProfileManager = RestService.shared.createOperationsManager(from: self, type: RestProfileManager.self)
    
    public func openInitController(in window: UIWindow) {
        self.window = window
        window.rootViewController = rootNavigationController
        window.makeKeyAndVisible()
        SplashRouter(in: rootNavigationController).openSplash()
        FirebaseService.shared.listenMaintenace { (mainentance) in
            self.isMaintanance = mainentance
            if mainentance {
                SplashRouter(in: self.rootNavigationController).showNoInternet(delegate: nil, message: R.string.localizable.maintenance(), withRetry: false)
            } else {
                if let topController = self.rootNavigationController.presentedViewController as? NoInternetViewController {
                    topController.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    public func openApp(newEmail: Bool = false, isSkiped: Bool = false) {
        clearPresentedController { [weak self] in
            guard let self = self else {
                return
            }
            if ArchiveService.shared.tokenModel != nil {
                self.getCurrentUser(isSkiped)
            } else {
                AuthorizationRouter(in: self.rootNavigationController).openMainScreen()
            }
        }
    }

    public func exitApp(newEmail: Bool = false) {
        clearPresentedController { [weak self] in
            guard let self = self else { return }
            
            ArchiveService.shared.tokenModel = nil
            ArchiveService.shared.userModel = nil
            SubscriptionsManager.shared.reset()
            AuthorizationRouter(in: self.rootNavigationController).setRootSignInScreen(newEmail)
            RestService.shared.profileChanged()
            NotificationsService.shared.deactivateToken()
        }
    }
    
    func clearPresentedController(completion: @escaping () -> Void) {
        if let topController = UIApplication.topViewController(), topController.presentingViewController != nil {
            topController.dismiss(animated: true) { [unowned self] in
                self.clearPresentedController(completion: completion)
            }
        } else {
            completion()
        }
    }
    
    private func getCurrentUser(_ isSkiped: Bool = false) {
        profileManager.getUser()
            .onComplete { [weak self] (result) in
                if let user = result.result {
                    if let self = self,
                       self.rootNavigationController.viewControllers.first is MainViewController {
                        self.rootNavigationController.setViewControllers([self.rootNavigationController.viewControllers.last!], animated: false)
                    }
                    ArchiveService.shared.userModel = user
                    ArchiveService.shared.currentProfile = user.profile.selectorProfile
                    ArchiveService.shared.seeBusinessContent = user.profile.seeBusinessPosts
                    
                    let myInterestsCount = result.result?.profile.hashtags.count ?? 0
                    ArchiveService.shared.interestExist = myInterestsCount != 0
                    if myInterestsCount == 0 && !isSkiped {
                        BasicProfileRouter(in: self?.rootNavigationController).openMyInterestsViewController(type: .create)
                    } else {
                        AuthorizationRouter(in: self?.rootNavigationController).openMainScreen()
                    }
                    NotificationsService.shared.askForNotification()
                    NotificationsService.shared.updateFirebaseToken()
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
