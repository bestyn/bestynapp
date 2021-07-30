//
//  RestService.swift
//  neighbourhood
//
//  Created by Dioksa on 08.06.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import GBKSoftRestManager

class RestService {

    static let shared = RestService()

    private lazy var authManager: RestAuthorizationManager = createOperationsManager(from: self)
    private(set) var setupComplete = false

    func setupRestManager() {
        RestManager.shared.configuration.setAuthorisationHeaderSource { () -> String in
            if let token = ArchiveService.shared.tokenModel?.token {
                return "Bearer \(token)"
            }
            return ""
        }
        RestManager.shared.configuration.setTokenRefresher { (completion) in
            guard let refreshToken = ArchiveService.shared.tokenModel?.refreshToken else {
                completion(false)
                return
            }
            self.authManager.refreshAuthToken(with: refreshToken)
                .onError { (error) in
                    print(error)
                    completion(false)
                }
                .onComplete { (response) in
                    if let tokenModel = response.result {
                        ArchiveService.shared.tokenModel = tokenModel
                        completion(true)
                    } else {
                        completion(false)
                    }
                }.run()
        }

        RestManager.shared.configuration.setDefaultHeaders(["X-Version": Configuration.buildVersion])
        RestManager.shared.configuration.setHeaderValidation { (headers) -> Bool in
            guard let currentMajorVersion = Configuration.buildVersion.split(separator: ".").first,
                let serverVersion = headers.first(where: {($0.key as? String)?.lowercased() == "x-version"})?.value as? String,
                serverVersion != "unknown",
                let serverMajorVersion = serverVersion.split(separator: ".").first else {
                    return true
            }
            if currentMajorVersion == serverMajorVersion {
                return true
            }
            DispatchQueue.main.async {
                self.openUpdate()
            }
            return false
        }

        NotificationCenter.default.addObserver(self, selector: #selector(profileChanged), name: .profileDidChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(profileChanged), name: .profileDidSet, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(internetStatusChanged(notification:)), name: ReachabilityService.shared.reachabilityStatusChanged, object: nil)
    }



    @objc public func profileChanged() {
        guard let profileID = ArchiveService.shared.currentProfile?.id else {
            RestManager.shared.configuration.setDefaultHeader(header: "profileId", value: "")
            return
        }
        RestManager.shared.configuration.setDefaultHeader(header: "profileId", value: "\(profileID)")
    }

    @objc private func internetStatusChanged(notification: Notification) {
        guard !setupComplete,
           let status = notification.userInfo?["status"] as? ReachabilityStatus,
           status == .reachable else {
            return
        }
        FirebaseService.shared.getPreAppVersion { (version) in
            if version == Configuration.buildVersion {
                RestManager.shared.configuration.setBaseURL(Configuration.reviewBaseURL.absoluteString)
            } else {
                RestManager.shared.configuration.setBaseURL(Configuration.baseURL.absoluteString)
            }
            self.setupComplete = true
            NotificationCenter.default.post(name: .restSetupComplete, object: nil)
        }
    }

    private func openUpdate() {
        let appName = Configuration.appName
        Alert(title: Alert.Title.needUpdate(appName: appName), message: Alert.Message.needUpdate(appName: appName))
            .configure(doneText: Alert.Action.update)
            .configure(allowDismiss: false)
            .show { (_) in
                if let url = URL(string: "https://itunes.apple.com/us/app/apple-store/id1528179376?mt=8"), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
        }
    }

    func setUnauthHandler(_ handler: @escaping UnauthorizedHandler) {
        RestManager.shared.configuration.setUnauthorizedHandler(handler)
    }

    func createOperationsManager<T: RestOperationsManager>(from context: AnyObject, type: T.Type = T.self) -> T {
        return RestManager.shared.operationsManager(from: type, in: context)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
