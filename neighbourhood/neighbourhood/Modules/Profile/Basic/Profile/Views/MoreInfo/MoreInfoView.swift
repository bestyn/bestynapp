//
//  MoreInfoView.swift
//  neighbourhood
//
//  Created by Dioksa on 04.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

protocol MoreInfoViewDelegate: class {
    func openPage(_ page: PageType)
    func logout()
}

final class MoreInfoView: UIView, PopoverPresentedView {
    @IBOutlet private weak var policyTitle: UILabel!
    @IBOutlet private weak var termsTitle: UILabel!
    @IBOutlet private weak var aboutTitle: UILabel!
    @IBOutlet private weak var logoutTitle: UILabel!
    
    weak var delegate: MoreInfoViewDelegate?
    weak var popoverPresenter: PopoverViewController?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
        setTexts()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }
    
    private func initView() {
        loadFromXib(R.nib.moreInfoView.name, contextOf: MoreInfoView.self)
    }
    
    private func setTexts() {
        policyTitle.text = R.string.localizable.privacyTitle()
        termsTitle.text = R.string.localizable.termsConditionsTitle()
        aboutTitle.text = R.string.localizable.aboutTitle()
        logoutTitle.text = R.string.localizable.logOutTitle()
    }
    
    // MARK: - Private actions
    @IBAction private func policyButtonDidTap(_ sender: UIButton) {
        delegate?.openPage(.policy)
        popoverPresenter?.close()
    }
    
    @IBAction private func termsButtonDidTap(_ sender: UIButton) {
        delegate?.openPage(.terms)
        popoverPresenter?.close()
    }
    
    @IBAction private func aboutButtonDidTap(_ sender: UIButton) {
        delegate?.openPage(.about)
        popoverPresenter?.close()
    }
    
    @IBAction private func logOutButtonDidTap(_ sender: UIButton) {
        popoverPresenter?.close(completion: {
            self.delegate?.logout()
        })
    }
}
