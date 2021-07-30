//
//  PublicInterestsView.swift
//  neighbourhood
//
//  Created by Administrator on 21.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import TagListView

class PublicInterestsView: UIView {
    
    @IBOutlet private weak var tagView: TagListView!

    // MARK: - Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }
    
    private func initView() {
        loadFromXib(R.nib.publicInterestsView.name, contextOf: PublicInterestsView.self)
        tagView.textFont = R.font.poppinsMedium(size: 13)!
    }
    
    // MARK: - Internal API
    func configure(with profile: PublicProfileModel) {
        tagView.removeAllTags()
        profile.hashtags.forEach {
            tagView.addTag($0.name)
        }
    }
}
