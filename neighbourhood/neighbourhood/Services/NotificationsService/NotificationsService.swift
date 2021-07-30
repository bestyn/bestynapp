//
//  NotificationsService.swift
//  neighbourhood
//
//  Created by Artem Korzh on 10.11.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import UserNotifications
import FirebaseMessaging
import Firebase

class NotificationsService: NSObject {

    public static let shared = NotificationsService()
    private override init() {}

    var navigationController: UINavigationController { RootRouter.shared.rootNavigationController }

    public func registerForNotifications() {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self

        let authOptions: UNAuthorizationOptions = [.alert, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in })
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    private lazy var notificationsOM: RestNotificationsManager = RestService.shared.createOperationsManager(from: self)

    public func didReceiveDeviceToken(_ deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        Messaging.messaging().setAPNSToken(deviceToken, type: .unknown) // .sandbox // .prod

        print("Device token: \(deviceToken.map { String(format: "%02.2hhx", arguments: [$0]) }.joined())")
        print("FcmToken: \(Messaging.messaging().fcmToken ?? (""))")
    }

    public func updateFirebaseToken() {
        guard let token = Messaging.messaging().fcmToken else {
            return
        }
        restStoreToken(token)
    }

    public func deactivateToken() {
        InstanceID.instanceID().deleteID { (error) in
            if let error = error {
                print("Firebase token deactivation failed", error)
            }
        }
    }

    public func askForNotification() {
        if ArchiveService.shared.notificationLater == nil {
            let appName = Configuration.appName
            Alert(title: Alert.Title.askNotification(appName: appName), message: Alert.Message.askNotification(appName: appName))
                .configure(doneText: Alert.Action.later)
                .configure(cancelText: Alert.Action.allow)
                .configure(allowDismiss: false)
                .show { (result) in
                    switch result {
                    case .done:
                        ArchiveService.shared.notificationLater = true
                    case .cancel:
                        ArchiveService.shared.notificationLater = false
                        self.checkNotificationsEnabled(notifyDisabled: false)
                    default:
                        break
                    }
                }
            return
        }
        ArchiveService.shared.notificationLater = false
        self.checkNotificationsEnabled(notifyDisabled: false)
    }

    public func checkNotificationsEnabled(notifyDisabled: Bool = true) {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            switch settings.authorizationStatus {
            case .notDetermined, .authorized:
                self.registerForNotifications()
            case .denied:
                if notifyDisabled {
                    DispatchQueue.main.async {
                        self.notifyNotificationsDisabled()
                    }
                }
            default:
                break
            }
        }
    }

    private func notifyNotificationsDisabled() {
        Alert(title: Alert.Title.notificationPermission, message: Alert.Message.notificationPermission)
            .configure(doneText: Alert.Action.settings)
            .configure(cancelText: Alert.Action.close)
            .show { (result) in
                if result == .done {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                    }
                }
        }
    }

    private func openNotificationsList() {

    }
}

// MARK: - REST request

extension NotificationsService {

    private func restStoreToken(_ token: String) {
        notificationsOM.saveToken(token: token).run()
    }
}

// MARK: - UNUserNotificationCenterDelegate, MessagingDelegate

extension NotificationsService: UNUserNotificationCenterDelegate, MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")

        if ArchiveService.shared.tokenModel != nil {
            restStoreToken(fcmToken)
        }
    }

    // swiftlint:disable:next line_length
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let content = response.notification.request.content
        if let payload = content.userInfo as? [String: Any] {
            navigate(payload: payload)
        } else {
            openNotificationsList()
        }
        completionHandler()
    }

    // swiftlint:disable:next line_length
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if shouldShow(notification: notification) {
            completionHandler([.alert, .sound])
        } else {
            completionHandler([])
        }
    }
}

// MARK: - Should show

extension NotificationsService {

    private func shouldShow(notification: UNNotification) -> Bool {
        guard let payload = notification.request.content.userInfo as? [String: Any] else {
            return true
        }
        if let path = payload["path"] as? String, path.contains("/chat/"),
           isChatScreen(for: payload) {
            return false
        }
        return true
    }

    private func isChatScreen(for payload: [String: Any]) -> Bool {
        if let chatController = RootRouter.shared.rootNavigationController.viewControllers.last as? ChatDetailsViewController,
           let profileIDString = payload["profileId"] as? String,
           let profileID = Int(profileIDString),
           ArchiveService.shared.currentProfile?.id == profileID,
           let senderProfileIDString = payload["senderProfileId"] as? String,
           let senderProfileID = Int(senderProfileIDString),
           chatController.viewModel.opponent.id == senderProfileID {
            return true
        }

        return false
    }
}

// MARK: - Navigation

extension NotificationsService {
    private func navigate(payload: [String: Any]) {
        guard let path = payload["path"] as? String else {
            return
        }

        switch path {
        case _ where path.contains("/chat/"):
            RootRouter.shared.clearPresentedController { [weak self] in
                self?.navigateToChat(payload: payload)
            }
        case _ where path.matches(for: "profile/(\\d+)/followers").count > 0:
            RootRouter.shared.clearPresentedController { [weak self] in
                self?.openFollowers(payload: payload)
            }
        case _ where path.matches(for: "profile/(\\d+)/post/(\\d+)").count > 0:
            RootRouter.shared.clearPresentedController { [weak self] in
                self?.openMention(payload: payload)
            }
        default:
            DynamicLinksService.shared.parseDynamicLink(link: path)
        }
    }

    private func navigateToChat(payload: [String: Any]) {
        guard let senderProfileIDString = payload["senderProfileId"] as? String,
              let senderProfileID = Int(senderProfileIDString),
              let profileIDString = payload["profileId"] as? String,
              let profileID = Int(profileIDString),
              let userFullName = payload["senderFullName"] as? String else {
            return
        }

        if ArchiveService.shared.currentProfile?.id != profileID,
           let profile = ArchiveService.shared.userModel?.profiles.first(where: {$0.id == profileID}) {
            UserModel.setActiveProfile(profile)
        }
        let opponent = ChatProfile(id: senderProfileID, avatar: nil, fullName: userFullName, type: .basic, isOnline: false)
        ChatRouter(in: navigationController).opeChatDetailsViewController(with: opponent)
    }

    private func openFollowers(payload: [String: Any]) {
        guard let profileIDString = payload["profileId"] as? String,
              let profileID = Int(profileIDString) else {
                return
              }
        if ArchiveService.shared.currentProfile?.id != profileID,
           let profile = ArchiveService.shared.userModel?.profiles.first(where: {$0.id == profileID}) {
            UserModel.setActiveProfile(profile)
        }
        MainScreenRouter(in: navigationController).openMyProfile()
        FollowRouter(in: navigationController).openFollowers()
    }

    private func openMention(payload: [String: Any]) {
        guard let profileIDString = payload["profileId"] as? String,
              let profileID = Int(profileIDString),
              let postIDString = payload["postId"] as? String,
              let postID = Int(postIDString) else {
                return
              }
        if ArchiveService.shared.currentProfile?.id != profileID,
           let profile = ArchiveService.shared.userModel?.profiles.first(where: {$0.id == profileID}) {
            UserModel.setActiveProfile(profile)
        }
        MainScreenRouter(in: navigationController).openHomeFeed()
        MyPostsRouter(in: navigationController).openPostDetailsViewController(postId: postID, profileDelegate: nil)
    }
}


