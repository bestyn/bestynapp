//
//  SmallAvatarView.swift
//  neighbourhood
//
//  Created by Artem Korzh on 17.09.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

@IBDesignable
class SmallAvatarView: BaseAvatarView {

    override var strokeImage: UIImage? { isBusiness ? R.image.avatar_round_business_small() : R.image.avatar_round_small() }

    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }

    private func initView() {
        loadFromXib(R.nib.smallAvatarView.name, contextOf: SmallAvatarView.self)
    }

    override func avatarUpdated(withImage: Bool) {
        super.avatarUpdated(withImage: withImage)
        strokeImageView.image = withImage ? R.image.avatar_round_grey() : strokeImage
    }
}
