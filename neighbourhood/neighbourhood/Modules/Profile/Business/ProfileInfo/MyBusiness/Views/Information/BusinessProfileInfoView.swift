//
//  BusinessProfileInfoView.swift
//  neighbourhood
//
//  Created by Dioksa on 04.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import TagListView

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
    @IBOutlet private weak var tagView: TagListView!
    @IBOutlet private weak var descriptionTitleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    
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
        loadFromXib(R.nib.businessProfileInfoView.name, contextOf: BusinessProfileInfoView.self)
        tagView.textFont = R.font.poppinsMedium(size: 13)!
        websiteTextView.delegate = self
    }
    
    func updateProfileView(profile: BusinessProfile?) {
        guard let profile = profile else { return }
        
        addressLabel.text = profile.address
        milesLabel.text = String(profile.radius.rawValue) + " " + R.string.localizable.milesWord()
        descriptionLabel.text = profile.description
        
        fillEmailLabel(data: profile.email, label: emailLabel)
        configureTextColor(for: profile.email, in: emailLabel)
        definePhoneLabelText(phone: profile.phone)
        defineWebsiteLabelText(site: profile.site)
        
        tagView.removeAllTags()
        
        profile.categories.forEach {
            tagView.addTag($0.title)
        }
    }
    
    private func configureTextColor(for text: String?, in label: UILabel) {
        if text != nil && text != "" {
            label.textColor = R.color.mainBlack()
        } else {
            label.textColor = R.color.greyMedium()
        }
    }
    
    private func setTexts() {
        addressTitleLable.text = R.string.localizable.businessAddressTitle()
        emailTitleLabel.text = R.string.localizable.businessEmailTitle()
        descriptionTitleLabel.text = R.string.localizable.businessDescriptionTitle()
        websiteTitleLabel.text = R.string.localizable.businessWebsiteTitle()
        phoneTitleLabel.text = R.string.localizable.businessPhoneTitle()
        milesTitleLabel.text = R.string.localizable.businessVisibilityRadiusTitle()
    }
    
    private func fillEmailLabel(data: String?, label: UILabel) {
        if data != nil && data != "" {
            label.text = data
        } else {
            label.text = R.string.localizable.notSetText()
        }
    }
    
    private func definePhoneLabelText(phone: Int?) {
        if let phone = phone {
            phoneLabel.formattedNumber(number: String(phone))
            configureTextColor(for: String(phone), in: phoneLabel)
        } else {
            phoneLabel.text = R.string.localizable.notSetText()
            configureTextColor(for: nil, in: phoneLabel)
        }
    }
    
    private func defineWebsiteLabelText(site: String?) {
        if let site = site, site != "" {
            let attributedString = NSMutableAttributedString(string: site)
            attributedString.addAttribute(.underlineStyle, value: NSNumber(value: true), range: NSRange(location: 0, length: site.count))
            attributedString.addAttribute(.link, value: site, range: NSRange(location: 0, length: site.count))
            attributedString.addAttributes([.foregroundColor: R.color.accentBlue()!,
                                            .font: R.font.poppinsRegular(size: 13)!],
                                           range: NSRange(location: 0, length: site.count))
            
            websiteTextView.attributedText = attributedString
        } else {
            let attributedString = NSMutableAttributedString(string: R.string.localizable.notSetText())
            attributedString.addAttributes([.foregroundColor: R.color.greyMedium()!,
                                            .font: R.font.poppinsRegular(size: 14)!],
                                           range: NSRange(location: 0, length: attributedString.string.count))
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
