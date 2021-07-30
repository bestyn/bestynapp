//
//  MoreInfoView.swift
//  neighbourhood
//
//  Created by Dioksa on 04.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

protocol StaticTextDelegate: AnyObject {
    func showText(for page: PageType)
}

final class MoreInfoView: UIView {
    @IBOutlet private weak var policyTitle: UILabel!
    @IBOutlet private weak var termsTitle: UILabel!
    @IBOutlet private weak var aboutTitle: UILabel!
    
    @IBAction func policyButtonDidTap(_ sender: UIButton) {
        delegate?.showText(for: .policy)
    }
    
    @IBAction func termsButtonDidTap(_ sender: UIButton) {
        delegate?.showText(for: .terms)
    }
    
    @IBAction func aboutButtonDidTap(_ sender: UIButton) {
        delegate?.showText(for: .about)
    }
    
    weak var delegate: StaticTextDelegate?
    
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
    }
}
