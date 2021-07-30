//
//  MyInterestsView.swift
//  neighbourhood
//
//  Created by Dioksa on 04.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import TagListView

protocol MyInterestsViewDelegate: AnyObject {
    func openMyInterestsScreen()
}

final class MyInterestsView: UIView {
    @IBOutlet private weak var selectedInterestsTitleLabel: UILabel!
    @IBOutlet private weak var tagView: TagListView!
    
    weak var screenDelegate: MyInterestsViewDelegate?

    public var hashtags: [HashtagModel] = [] {
        didSet { updateList() }
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
        loadFromXib(R.nib.myInterestsView.name, contextOf: MyInterestsView.self)
        tagView.textFont = R.font.poppinsMedium(size: 13)!
    }
    
    func updateList() {
        tagView.removeAllTags()
        hashtags.forEach {
            tagView.addTag($0.name)
        }
    }
    
    // MARK: - Private actions
    @IBAction private func editButtonDidTap(_ sender: UIButton) {
        screenDelegate?.openMyInterestsScreen()
    }
}
