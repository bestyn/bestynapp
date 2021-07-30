//
//  BusinessProfileInfoView.swift
//  neighbourhood
//
//  Created by Dioksa on 04.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces

final class BusinessProfileInfoView: UIView {
    @IBOutlet private weak var addressTitleLable: UILabel!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var emailTitleLabel: UILabel!
    @IBOutlet private weak var emailLabel: UILabel!
    @IBOutlet private weak var websiteTitleLabel: UILabel!
    @IBOutlet private weak var websiteTextView: UITextView!
    @IBOutlet private weak var phoneTitleLabel: UILabel!
    @IBOutlet private weak var phoneLabel: UILabel!
    @IBOutlet private weak var milesTitleLabel: UILabel!
    @IBOutlet private weak var milesLabel: UILabel!
    
    @IBOutlet private weak var emailStackView: UIStackView!
    @IBOutlet private weak var websiteStackView: UIStackView!
    @IBOutlet private weak var phoneStackView: UIStackView!
    @IBOutlet private weak var milesStackView: UIStackView!

    public var profile: BusinessProfile? {
        didSet { fillData() }
    }
    private let needsToShowHouse: Bool
    
    init(needsToShowHouse: Bool) {
        self.needsToShowHouse = needsToShowHouse
        super.init(frame: .zero)
        initView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initView() {
        loadFromXib(R.nib.businessProfileInfoView.name, contextOf: BusinessProfileInfoView.self)
        websiteTextView.delegate = self
        setTexts()
        setupTouches()
    }

}

extension BusinessProfileInfoView {

    private func setTexts() {
        addressTitleLable.text = R.string.localizable.businessAddressTitle()
        emailTitleLabel.text = R.string.localizable.businessEmailTitle()

        /// Do not delete empty space
        websiteTitleLabel.text = " \(R.string.localizable.businessWebsiteTitle())"
        phoneTitleLabel.text = R.string.localizable.businessPhoneTitle()
        milesTitleLabel.text = R.string.localizable.businessVisibilityRadiusTitle()
    }

    private func setupTouches() {
        let emailTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(openEmail))
        let phoneTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(openPhone))
        emailLabel.addGestureRecognizer(emailTapRecognizer)
        phoneLabel.addGestureRecognizer(phoneTapRecognizer)
        emailLabel.isUserInteractionEnabled = true
        phoneLabel.isUserInteractionEnabled = true
    }

    @objc private func openEmail() {
        guard let email = profile?.email,
              let url = URL(string: "mailto:\(email)"),
              UIApplication.shared.canOpenURL(url) else {
            return
        }
        UIApplication.shared.open(url)
    }

    @objc private func openPhone() {
        guard let phone = profile?.phone,
              let url = URL(string: "tel:\(phone)"),
              UIApplication.shared.canOpenURL(url) else {
            return
        }
        UIApplication.shared.open(url)
    }
}

extension BusinessProfileInfoView {
    
    func fillData() {
        guard let profile = profile else { return }
        addressLabel.text = profile.address

        milesStackView.isHidden = !needsToShowHouse
        
        milesLabel.text = "\(profile.radius.value) \(R.string.localizable.milesWord())"
        
        fillEmailLabel(data: profile.email, label: emailLabel)
        configureTextColor(for: profile.email, in: emailLabel)
        definePhoneLabelText(phone: profile.phone)
        defineWebsiteLabelText(site: profile.site)
    }
    
    private func configureTextColor(for text: String?, in label: UILabel) {
        if text != nil && text != "" {
            label.textColor = R.color.mainBlack()
        } else {
            label.textColor = R.color.greyMedium()
        }
    }

    private func fillEmailLabel(data: String?, label: UILabel) {
        if data != nil && data != "" {
            label.text = data
        } else {
            label.text = R.string.localizable.notSetText()
        }
    }
    
    private func definePhoneLabelText(phone: String?) {
        if let phone = phone, phone != "" {
            phoneLabel.text = phone.formattedPhoneNumber
            configureTextColor(for: phone, in: phoneLabel)
        } else {
            phoneLabel.text = R.string.localizable.notSetText()
            configureTextColor(for: nil, in: phoneLabel)
        }
    }
    
    private func defineWebsiteLabelText(site: String?) {
        if let site = site, site != "" {
            let attributedString = NSMutableAttributedString(string: site,
                                                             attributes: [.foregroundColor: R.color.accentBlue()!,
                                                                          .font: R.font.poppinsRegular(size: 13)!,
                                                                          .underlineStyle: NSNumber(value: true),
                                                                          .link: site])
            websiteTextView.attributedText = attributedString
        } else {
            let attributedString = NSMutableAttributedString(string: R.string.localizable.notSetText(),
                                                             attributes: [.foregroundColor: R.color.greyMedium()!,
                                                                          .font: R.font.poppinsRegular(size: 14)!])
            
            websiteTextView.attributedText = attributedString
        }
    }
}

// MARK: - UITextViewDelegate
extension BusinessProfileInfoView: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        UIApplication.shared.open(URL)
        return false
    }
}
