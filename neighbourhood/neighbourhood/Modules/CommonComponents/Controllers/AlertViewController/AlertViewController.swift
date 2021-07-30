//
//  AlertViewController.swift
//  neighbourhood
//
//  Created by Dioksa on 22.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

class AlertViewController: UIViewController {

    @IBOutlet private weak var popupView: UIView!
    @IBOutlet private weak var titleLabel: HeadingLabel!
    @IBOutlet private weak var messageLabel: ParagraphLabel!
    @IBOutlet private weak var linkButton: UIButton!
    @IBOutlet private weak var negativeButton: GreyButton!
    @IBOutlet private weak var positiveButton: DarkButton!
    @IBOutlet private weak var buttonsStackView: UIStackView!

    private let alert: Alert
    private var completion: AlertCompletion?

    init(alert: Alert, completion: AlertCompletion? = nil) {
        self.alert = alert
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewUI()
        fillView()
    }

    @IBAction func didTapLink(_ sender: Any) {
        self.completion?(.link)
    }

    @IBAction func didTapCancel(_ sender: Any) {
        dismiss(animated: true) {
            self.completion?(.cancel)
        }
    }

    @IBAction func didTapDone(_ sender: Any) {
        dismiss(animated: true) {
            self.completion?(.done)
        }
    }

    @IBAction func didTapDismiss(_ sender: Any) {}
}

extension AlertViewController {

    private func setupViewUI() {
        popupView.layer.cornerRadius = 30
    }

    private func fillView() {
        titleLabel.text = alert.title
        messageLabel.text = alert.message
        linkButton.setTitle(alert.linkText, for: .normal)
        linkButton.isHidden = alert.linkText == nil
        negativeButton.setTitle(alert.cancelText, for: .normal)
        negativeButton.isHidden = alert.cancelText == nil
        positiveButton.setTitle(alert.doneText, for: .normal)
        buttonsStackView.axis = alert.buttonsAxis
        if alert.buttonsAxis == .vertical {
            buttonsStackView.addArrangedSubview(buttonsStackView.arrangedSubviews[0])
        }
    }
}
