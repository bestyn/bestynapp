//
//  ProfileAvatarView.swift
//  neighbourhood
//
//  Created by Artem Korzh on 19.08.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

@IBDesignable
class ProfileSelectorView: UIView {

    @IBOutlet weak var unreadIndicatorView: UIView!
    @IBOutlet weak var dropDownIndicatorImageView: UIButton!
    @IBOutlet weak var avatarView: SmallAvatarView!

    @IBInspectable var isWhiteDropDownIndicator: Bool = false {
        didSet {
            dropDownIndicatorImageView.setImage(isWhiteDropDownIndicator ? R.image.arrow_down_white() : R.image.arrow_down(), for: .normal)
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

    override func awakeFromNib() {
        super.awakeFromNib()
        update()
    }

    private func initView() {
        loadFromXib(R.nib.profileSelectorView.name, contextOf: ProfileSelectorView.self)
        NotificationCenter.default.addObserver(self, selector: #selector(updateUnreadIndicator), name: .chatUnreadMessageServiceUpdateUnreadMessageNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(update), name: .profileDidChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateLayout), name: .tabbarUpdated, object: nil)
        updateIndicatorState()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        avatarView.layoutSubviews()
    }

    @IBAction func didTapView(_ sender: Any) {
        NotificationCenter.default.post(name: .profileSelectorDidPressed, object: nil)
    }

    @objc public func update() {
        guard let profile = ArchiveService.shared.currentProfile else {
            return
        }
        let avatarURL = profile.avatar?.formatted?.small
        avatarView.isBusiness = profile.type == .business
        avatarView.updateWith(imageURL: avatarURL, fullName: profile.fullName)
        avatarView.layoutSubviews()
    }
    @objc public func updateLayout() {
        avatarView.layoutSubviews()
    }

    @objc private func updateUnreadIndicator(_ notification: NSNotification) {
        updateIndicatorState()
    }

    private func updateIndicatorState() {
        if ArchiveService.shared.userModel?.profile.hasUnreadMessages == true ||
            ArchiveService.shared.userModel?.businessProfiles?.contains(where: { $0.hasUnreadMessages ?? false }) == true {
            DispatchQueue.main.async {
                self.unreadIndicatorView.isHidden = false
            }
            
            return
        }
        unreadIndicatorView.isHidden = true
    }
}
