//
//  Alert.swift
//  neighbourhood
//
//  Created by Dioksa on 22.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

typealias AlertCompletion = (Alert.AlertStatus) -> Void

class Alert {

    enum AlertStatus {
        case done
        case cancel
        case link
        case dismiss
    }

    private(set) var title: String?
    private(set) var message: String?

    private(set) var cancelText: String?
    private(set) var doneText: String = Alert.Action.ok
    private(set) var linkText: String?

    private(set) var allowDismiss: Bool = true
    private(set) var buttonsAxis: NSLayoutConstraint.Axis = .horizontal

    init(title: String? = nil, message: String? = nil) {
        self.title = title
        self.message = message
    }

    func configure(cancelText: String) -> Alert {
        self.cancelText = cancelText
        return self
    }

    func configure(doneText: String) -> Alert {
        self.doneText = doneText
        return self
    }

    func configure(linkText: String) -> Alert {
        self.linkText = linkText
        return self
    }

    func configure(allowDismiss: Bool) -> Alert {
        self.allowDismiss = allowDismiss
        return self
    }

    func configure(buttonsAxis: NSLayoutConstraint.Axis) -> Alert {
        self.buttonsAxis = buttonsAxis
        return self
    }

    func show(completion: AlertCompletion? = nil) {
        let controller = AlertViewController(alert: self, completion: completion)
        controller.modalPresentationStyle = .overCurrentContext
        UIApplication.topViewController()?.present(controller, animated: true)
    }
}
