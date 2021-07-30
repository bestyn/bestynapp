//
//  ReactionPicker.swift
//  neighbourhood
//
//  Created by Artem Korzh on 13.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

protocol ReactionPickerDelegate: class {
    func reactionSelected(_ reaction: Reaction)
}

@IBDesignable
class ReactionPicker: UIView {

    @IBOutlet var containerView: UIView!
    @IBOutlet var reactionsStackView: UIStackView!

    public weak var delegate: ReactionPickerDelegate?
    
    @IBInspectable var isReversed: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }

    private func initView() {
        loadFromXib(R.nib.reactionPicker.name, contextOf: ReactionPicker.self)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        containerView.dropShadow()
        setupReactionsButtons()
    }

    private func setupReactionsButtons() {
        reactionsStackView.arrangedSubviews.forEach({$0.removeFromSuperview()})
        
        let reactions = self.isReversed ? Reaction.allCases.reversed() : Reaction.allCases
        reactions.forEach { (reaction) in
            let button = UIButton()
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalTo: button.heightAnchor)
            ])
            button.setImage(reaction.image, for: .normal)
            button.addTarget(self, action: #selector(didTapButton(_:)), for: .touchUpInside)
            reactionsStackView.addArrangedSubview(button)
        }
    }

    @objc private func didTapButton(_ button: UIButton) {
        guard let index = reactionsStackView.arrangedSubviews.firstIndex(of: button) else {
            return
        }
        
        let reactions = self.isReversed ? Reaction.allCases.reversed() : Reaction.allCases
        delegate?.reactionSelected(reactions[index])
    }
}
