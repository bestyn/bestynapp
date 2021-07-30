//
//  SplashViewController.swift
//  neighbourhood
//
//  Created by Dioksa on 22.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

final class SplashViewController: BaseViewController {
    private let duration: Double = 1
    private lazy var configManager: RestConfigManager = RestService.shared.createOperationsManager(from: self, type: RestConfigManager.self)
    private let validation = ValidationManager()
    private var isGettingConfiguration = false
    private var retryCount = 0
    private let maxRetryCount = 3
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(getAppConfiguration), name: .restSetupComplete, object: nil)
        ArchiveService.shared.lastVisitedStory = nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if RestService.shared.setupComplete {
            getAppConfiguration()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if RestService.shared.setupComplete {
                return
            }
            if !ReachabilityService.shared.isConnection() {
                SplashRouter(in: self.navigationController).showNoInternet(delegate: self)
            }
        }
    }
    
    @objc private func getAppConfiguration() {
        navigationController?.dismiss(animated: true, completion: nil)
        guard !isGettingConfiguration else {
            return
        }
        if !RestService.shared.setupComplete {
            if !ReachabilityService.shared.isConnection() {
                SplashRouter(in: self.navigationController).showNoInternet(delegate: self)
            }
            return
        }
        isGettingConfiguration = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.restGetConfiguration()
        }
    }

    private func restGetConfiguration() {
        configManager.getConfig()
            .onStateChanged({ [weak self] (state) in
                if state == .ended, let self = self {
                    self.isGettingConfiguration = false
                    NotificationCenter.default.addObserver(self, selector: #selector(self.getAppConfiguration), name: UIApplication.didBecomeActiveNotification, object: nil)
                }
            })
            .onComplete { (result) in
                if RootRouter.shared.isMaintanance {
                    return
                }
                if let config = result.result {
                    ArchiveService.shared.config = config
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    RootRouter.shared.openApp()
                }
        } .onError { [weak self] (error) in
            if RootRouter.shared.isMaintanance {
                return
            }
            if case .executionError(_) = error,
               let self = self {
                if self.retryCount <= self.maxRetryCount {
                    self.retryCount += 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                        self?.restGetConfiguration()
                    }
                } else {
                    SplashRouter(in: self.navigationController).showNoInternet(delegate: self)
                }
                return
            }
            self?.handleError(error)
        } .run()
    }
}

// MARK: - LostInternetViewDelegate
extension SplashViewController: NoInternetDelegate {
    func didTapTryAgainButton() {
        getAppConfiguration()
    }
}
