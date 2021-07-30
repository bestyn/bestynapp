//
//  ProfileInfoView.swift
//  neighbourhood
//
//  Created by Dioksa on 04.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

final class ProfileInfoView: UIView {
    @IBOutlet private weak var addressTitleLable: UILabel!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var emailTitleLabel: UILabel!
    @IBOutlet private weak var emailLabel: UILabel!
    @IBOutlet private weak var birthdayTitleLabel: UILabel!
    @IBOutlet private weak var birthdayLabel: UILabel!
    @IBOutlet private weak var genderTitleLabel: UILabel!
    @IBOutlet private weak var genderLabel: UILabel!
    
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
        loadFromXib(R.nib.profileInfoView.name, contextOf: ProfileInfoView.self)
    }
    
    func updateProfileView(address: String?, email: String?, birthday: Double?, gender: UserGenderType?) {
        addressLabel.text = address
        emailLabel.text = email
        defineUserGenderButton(gender)
        
        let date = Date(timeIntervalSince1970: birthday ?? 0)
        birthdayLabel.text = DateFormatter.pickerFormatter.string(from: date)
        
        if birthday == nil {
            birthdayLabel.text = R.string.localizable.notSetText()
        }
    }
    
    private func setTexts() {
        addressTitleLable.text = R.string.localizable.addressTitle()
        emailTitleLabel.text = R.string.localizable.emailTitle()
        birthdayTitleLabel.text = R.string.localizable.birthdayTitle()
        genderTitleLabel.text = R.string.localizable.genderTitle()
    }
    
    private func defineUserGenderButton(_ gender: UserGenderType?) {
        switch gender {
        case .male:
            genderLabel.text = R.string.localizable.maleGenger()
        case .female:
            genderLabel.text = R.string.localizable.femaleGenger()
        case .other:
            genderLabel.text = R.string.localizable.otherGender()
        default:
            genderLabel.text = R.string.localizable.notSetText()
        }
    }
}
