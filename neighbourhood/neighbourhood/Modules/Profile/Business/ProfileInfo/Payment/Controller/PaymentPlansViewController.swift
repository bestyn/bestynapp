//
//  PaymentPlansViewController.swift
//  neighbourhood
//
//  Created by Dioksa on 15.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

final class PaymentPlansViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override var isNavigationBarVisible: Bool {
        return false
    }
    
    @IBAction private func backButtonDidTap(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
}
