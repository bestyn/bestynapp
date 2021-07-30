//
//  ProfileMarkerView.swift
//  iCare
//
//  Created by Dioksa on 30.03.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import Kingfisher

final class ProfileMarkerView: UIView {

    @IBOutlet private var contentView: UIView!
    @IBOutlet private weak var nameButton: UIButton!
    @IBOutlet weak var avatarView: MediumAvatarView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("ProfileMarkerView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = bounds
        backgroundColor = UIColor.clear
        isOpaque = false
    }
    
    public func updateView(imageUrl: URL?, name: String, profileName: String?) {
        avatarView.updateWith(imageURL: imageUrl, fullName: profileName ?? "")
        nameButton.setTitle(name, for: .normal)
    }
}
