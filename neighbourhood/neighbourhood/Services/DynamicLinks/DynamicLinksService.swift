//
//  DynamicLinksService.swift
//  neighbourhood
//
//  Created by Artem Korzh on 23.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import GBKSoftRestManager

class DynamicLinksService: ErrorHandling {
    
    enum LinkContains {
        static let verifyEmail = "/user/confirm-email/"
        static let changeEmail = "/user/change-email/"
        static let recoveryPassword = "reset-password"
    }
    
    static let shared = DynamicLinksService()
    private lazy var registrationManager: RestRegistrationManager = RestService.shared.createOperationsManager(from: self, type: RestRegistrationManager.self)
    
    private init() {}
    
    func parseDynamicLink(link: String) {
        switch link {
        case _ where link.contains(LinkContains.verifyEmail):
            guard let token = link.slice(from: LinkContains.verifyEmail, to: "&") else {
                NSLog("🔥 Error occurred while slicing token")
                return
            }
            verifyEmail(with: token)
        case _ where link.contains(LinkContains.changeEmail):
            guard let token = link.slice(from: LinkContains.changeEmail, to: "&") else {
                NSLog("🔥 Error occurred while slicing token")
                return
            }
            verifyChangeEmail(with: token)
        case _ where link.contains(LinkContains.recoveryPassword):
            guard let token = link.slice(from: "?token=", to: "&") else {
                NSLog("🔥 Error occurred while slicing token")
                return
            }
            recoveryPassword(token: token)
        default:
            break
        }
    }
    
    private func verifyEmail(with token: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.registrationManager.verifyEmail(token: token)
                .onComplete { (result) in
                    AnalyticsService.logConfirmEmail()
                    if let tokenModel = result.result, UserService.shared.token == nil {
                        ArchiveService.shared.tokenModel = tokenModel
                        RootRouter.shared.openApp()
                    }
                    Toast.show(message: Alert.Message.emailVerified)
            } .onError { [weak self] (error) in
                self?.handleError(error)
            } .run()
        }
    }
    
    private func verifyChangeEmail(with token: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.registrationManager.verifyChangeEmail(token: token)
                .onComplete { (result) in
                    RootRouter.shared.exitApp(newEmail: true)
                    Toast.show(message: R.string.localizable.changedEmailUpdated())
            } .onError { [weak self] (error) in
                self?.handleError(error)
            } .run()
        }
    }
    
    private func recoveryPassword(token: String) {
        if let navigationController = UIApplication.topViewController()?.navigationController {
            AuthorizationRouter(in: navigationController).openNewPassword(token: token)
        }
    }
}
