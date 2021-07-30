//
//  EmptyView.swift
//  neighbourhood
//
//  Created by Dioksa on 02.06.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

protocol EmptyViewActionDelegate: AnyObject {
    func openInterestsScreen()
}

final class EmptyView: UIView {
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private var contentView: UIView!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var interestsButton: UIButton!
    
    weak var delegate: EmptyViewActionDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
       
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
     
    func setAttributesForEmptyScreen(text: String, image: UIImage? = R.image.empty_post_icon(), isButtonVisible: Bool = false) {
        textLabel.text = text
        imageView.image = image
        interestsButton.isHidden = !isButtonVisible
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("EmptyView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = bounds
    }
    
    // MARK: - Private actions
    @IBAction private func interestsButtonDidTap(_ sender: UIButton) {
        delegate?.openInterestsScreen()
    }
}
