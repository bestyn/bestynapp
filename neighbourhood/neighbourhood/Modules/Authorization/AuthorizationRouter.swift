//
//  AuthorizationRouter.swift
//  neighbourhood
//
//  Created by Dioksa on 21.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import GBKRouterProtocol

struct AuthorizationRouter: GBKRouterProtocol {
    var context: UINavigationController!
    
    func setRootSignInScreen(_ isNewEmail: Bool = false) {
        let controller = SignInViewController()
        controller.isNewEmail = isNewEmail
        context.setViewControllers([controller], animated: true)
    }

    func openSignInScreen(_ isNewEmail: Bool = false) {
        let controller = SignInViewController()
        controller.isNewEmail = isNewEmail
        push(controller: controller)
    }
    
    func openForgotPasswordScreen() {
        push(controller: ForgotPasswordViewController())
    }
    
    public func openNewPassword(token: String) {
        context.setViewControllers([NewPasswordViewController(token: token)], animated: true)
    }
    
    func openMainScreen() {
        let controller = MainViewController()
        context.setViewControllers([controller], animated: true)
    }
}
