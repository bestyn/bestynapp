//
//  NoInternetViewController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 24.09.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

protocol NoInternetDelegate: class {
    func didTapTryAgainButton()
}

class NoInternetViewController: UIViewController {

    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var retryButton: UIButton!

    public var withRetry = true
    public var message = R.string.localizable.noInternetConnection()
    public weak var delegate: NoInternetDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        shadowView.dropShadow(color: .black, opacity: 0.15, offSet: CGSize(width: 0, height: 4), radius: 10)
        retryButton.isHidden = !withRetry
        retryButton.setTitle(R.string.localizable.retryButtonTitle(), for: .normal)
        messageLabel.text = message
    }

    @IBAction func didTapRetry(_ sender: Any) {
        dismiss(animated: true) {
            self.delegate?.didTapTryAgainButton()
        }
    }
}
