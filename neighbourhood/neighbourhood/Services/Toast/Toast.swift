//
//  Toast.swift
//  neighbourhood
//
//  Created by Dioksa on 22.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import Toast_Swift

class Toast {

    class func configure() {
        var style = ToastStyle()
//        style.backgroundColor = R.color.primaryDark()!
//        style.messageFont = R.font.sfProTextMedium(size: 14)!
//        style.messageColor = R.color.grayscaleDark()!
        style.cornerRadius = 4
        style.verticalPadding = 20
        style.horizontalPadding = 16
        style.displayShadow = true
        style.messageAlignment = .left
        ToastManager.shared.style = style
    }

    class func show(message: String) {
        let duration: TimeInterval = 2.5 + Double(message.count) / 40
        UIApplication.shared.keyWindow?.hideToast()
        UIApplication.shared.keyWindow?.makeToast(message, duration: duration, position: .bottom)
    }
}
