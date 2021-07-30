//
//  MediumAvatarView.swift
//  neighbourhood
//
//  Created by Artem Korzh on 17.09.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

@IBDesignable
class MediumAvatarView: BaseAvatarView {

    @IBOutlet weak var businessMarkView: UIView!

    @IBInspectable public var withMark: Bool = false

    override var isBusiness: Bool {
        didSet { businessMarkView.isHidden = !(withMark && isBusiness) }
    }

    override var strokeImage: UIImage? {
       return isBusiness ? R.image.avatar_round_business_small() : R.image.avatar_round_small()
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
        loadFromXib(R.nib.mediumAvatarView.name, contextOf: MediumAvatarView.self)
    }

    override func avatarUpdated(withImage: Bool) {
        super.avatarUpdated(withImage: withImage)
        strokeImageView.image = strokeImage
    }
}
