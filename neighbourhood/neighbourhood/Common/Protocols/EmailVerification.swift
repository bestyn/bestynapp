//
//  EmailVerification.swift
//  neighbourhood
//
//  Created by Dioksa on 28.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

protocol EmailVerification {
    func showEmailVerificationMessage(email: String, title: String, message: String?)
    func toggleEmailSendingLoader(shown: Bool)
}

extension EmailVerification where Self: UIViewController {
    
    func showEmailVerificationMessage(email: String, title: String, message: String? = nil) {
        if title == Alert.Title.changeEmail {
            Alert(title: title, message: message)
                .show { (result) in
                    switch result {
                    case .done:
                        AuthorizationRouter(in: self.navigationController).popToRootController()
                    default:
                        break
                    }
            }
        } else {
            let controller = ResendLinkViewController(email: email) { [weak self] in
                guard let self = self else {
                    return
                }
                AuthorizationRouter(in: self.navigationController).popToRootController()
            }
            controller.modalPresentationStyle = .overCurrentContext
            present(controller, animated: true, completion: nil)
        }
    }
    
    func showEmailChangeMessage(email: String) {
        Alert(title: Alert.Title.changeEmail, message: Alert.Title.changeEmail)
            .show { (result) in
                switch result {
                case .done:
                    AuthorizationRouter(in: self.navigationController).popToRootController()
                default:
                    break
                }
        }
    }
    
    private func showEmailVerificationSent() {
        Toast.show(message: Alert.Message.confirmEmail)
    }
    
    private func restSendVerificationLink(email: String) {
        let registrationManager: RestRegistrationManager = RestService.shared.createOperationsManager(from: self, type: RestRegistrationManager.self)
        registrationManager.sendVerificationLink(email: email)
            .onStateChanged({ [weak self] (state) in
                self?.toggleEmailSendingLoader(shown: state == .started)
            })
            .onComplete { [weak self] (_) in
                guard let self = self else {
                    return
                }
                self.showEmailVerificationSent()
        } .onError { [weak self] (error) in
            (self as? ErrorHandling)?.handleError(error)
        } .run()
    }
    
    func showRestorePasswordMessage() {
        Alert(title: Alert.Title.passwordRecover, message: Alert.Message.restorePasswordMessage)
            .show { _ in
                self.dismiss(animated: true, completion: nil)
        }
    }

    func toggleEmailSendingLoader(shown: Bool) {
        if let alertController = UIApplication.topViewController() {
            alertController.view.isUserInteractionEnabled = !shown
            if shown {
                let loader = UIActivityIndicatorView()
                loader.tintColor = R.color.accentBlue()
                loader.startAnimating()
                loader.translatesAutoresizingMaskIntoConstraints = false
                alertController.view.addSubview(loader)
                loader.centerYAnchor.constraint(equalTo: alertController.view.centerYAnchor).isActive = true
                loader.centerXAnchor.constraint(equalTo: alertController.view.centerXAnchor).isActive = true
            } else {
                alertController.view.subviews.first(where: {$0 is UIActivityIndicatorView})?.removeFromSuperview()
            }
        }
    }
}
