//
//  SplashRouter.swift
//  neighbourhood
//
//  Created by Artem Korzh on 24.09.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import GBKRouterProtocol

struct SplashRouter: GBKRouterProtocol {
    var context: UINavigationController!

    func openSplash() {
        let controller = SplashViewController()
        context.viewControllers = [controller]
    }

    func showNoInternet(delegate: NoInternetDelegate?, message: String? = nil, withRetry: Bool = true) {
        let controller = NoInternetViewController()
        controller.modalPresentationStyle = .overCurrentContext
        controller.delegate = delegate
        controller.withRetry = withRetry
        if let message = message {
            controller.message = message
        }
        present(controller: controller)
    }
}
