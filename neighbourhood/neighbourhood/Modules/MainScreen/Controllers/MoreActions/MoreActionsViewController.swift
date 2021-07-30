//
//  MoreActionsViewController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 16.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

enum MoreAction {
    case settings
    case payments
    case about
    case privacy
    case terms
    case logout
}

protocol MoreActionsDelegate: class {
    func moreActionSelected(action: MoreAction)
}

class MoreActionsViewController: UIViewController, BottomMenuPresentable {
    var transitionManager: BottomMenuPresentationManager! = .init()

    var presentedViewHeight: CGFloat { buttonsView.bounds.height }

    @IBOutlet weak var buttonsView: UIView!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var paymentsButton: UIButton!
    @IBOutlet weak var aboutButton: UIButton!
    @IBOutlet weak var privacyButton: UIButton!
    @IBOutlet weak var termsButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!

    private weak var delegate: MoreActionsDelegate?

    init(delegate: MoreActionsDelegate) {
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setTitles()
        paymentsButton.isHidden = ArchiveService.shared.currentProfile?.type != .business
    }

    private func setTitles() {
        settingsButton.setTitle(R.string.localizable.profileSettingsTitle(), for: .normal)
        paymentsButton.setTitle(R.string.localizable.paymentPlansButtonTitle(), for: .normal)
        aboutButton.setTitle(R.string.localizable.aboutTitle(), for: .normal)
        privacyButton.setTitle(R.string.localizable.privacyTitle(), for: .normal)
        termsButton.setTitle(R.string.localizable.termsConditionsTitle(), for: .normal)
        logoutButton.setTitle(R.string.localizable.logOutTitle(), for: .normal)
    }

    private func actionSelected(_ action: MoreAction) {
        dismiss(animated: true) {
            self.delegate?.moreActionSelected(action: action)
        }
    }

    @IBAction func didTapSettings(_ sender: Any) {
        actionSelected(.settings)
    }

    @IBAction func didTapPayments(_ sender: Any) {
        actionSelected(.payments)
    }

    @IBAction func didTapAbout(_ sender: Any) {
        actionSelected(.about)
    }

    @IBAction func didTapPrivacy(_ sender: Any) {
        actionSelected(.privacy)
    }

    @IBAction func didTapTerms(_ sender: Any) {
        actionSelected(.terms)
    }

    @IBAction func didTapLogout(_ sender: Any) {
        actionSelected(.logout)
    }

}
