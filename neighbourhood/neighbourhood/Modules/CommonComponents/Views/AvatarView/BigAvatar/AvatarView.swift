//
//  AvatarView.swift
//  neighbourhood
//
//  Created by Artem Korzh on 17.09.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

@IBDesignable
class AvatarView: BaseAvatarView {
    @IBInspectable public var initialsSize: CGFloat = 64 {
        didSet {
            initialsLabel.font = UIFont(name: initialsLabel.font.fontName, size: initialsSize)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }

    private func initView() {
        loadFromXib(R.nib.avatarView.name, contextOf: AvatarView.self)
    }
}
