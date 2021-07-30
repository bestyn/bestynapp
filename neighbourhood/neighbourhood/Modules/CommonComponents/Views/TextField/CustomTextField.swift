//
//  CustomTextField.swift
//  neighbourhood
//
//  Created by Dioksa on 30.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import GBKSoftTextField

final class CustomTextField: GBKSoftTextField {
    override func awakeFromNib() {
        super.awakeFromNib()
        Self.appearance().placeholderColor = R.color.greyMedium()!
        Self.appearance().placeholderFont = R.font.poppinsRegular(size: 14)
        
        Self.appearance().titleColor = R.color.mainBlack()!
        Self.appearance().titleFont = R.font.poppinsMedium(size: 14)
        
        Self.appearance().errorFont = R.font.poppinsMedium(size: 11)
        Self.appearance().errorColor = R.color.accentRed()!
        
        Self.appearance().underlineColor = R.color.greyStroke()!
        Self.appearance().errorPadding = CGSize(width: 0, height: 0)
        
        self.textColor = R.color.mainBlack()
        self.font = R.font.poppinsRegular(size: 14)
        
        Self.appearance().clearErrorOnFocus = true
    }
}
