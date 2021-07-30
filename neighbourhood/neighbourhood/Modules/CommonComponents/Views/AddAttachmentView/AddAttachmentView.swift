//
//  AddAttachmentView.swift
//  neighbourhood
//
//  Created by Dioksa on 22.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

final class AddAttachmentView: UIView {
    @IBOutlet private weak var attachLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }
    
    private func initView() {
        loadFromXib(R.nib.addAttachmentView.name, contextOf: AddAttachmentView.self)
        setTexts()
    }
    
    private func setTexts() {
        attachLabel.text = R.string.localizable.attachTitle()
    }
}
