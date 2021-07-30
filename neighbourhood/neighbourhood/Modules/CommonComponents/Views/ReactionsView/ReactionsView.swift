//
//  ReactionsView.swift
//  neighbourhood
//
//  Created by Artem Korzh on 13.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

@IBDesignable
class ReactionsView: UIView {
    
    @IBOutlet weak var reactionsStackView: UIStackView!
    @IBOutlet weak var countLabel: UILabel!

    public var reactions: [Reaction: Int] = [:] {
        didSet { fillData() }
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
        loadFromXib(R.nib.reactionsView.name, contextOf: ReactionsView.self)
    }

    private func fillData() {
        reactionsStackView.arrangedSubviews.forEach({$0.removeFromSuperview()})
        reactions.filter({$0.value > 0})
            .sorted(by: {$0.value > $1.value})
            .prefix(3)
            .forEach { (reaction, _) in
                let imageView = UIImageView(image: reaction.image)
                NSLayoutConstraint.activate([
                    imageView.heightAnchor.constraint(equalToConstant: 20),
                    imageView.widthAnchor.constraint(equalToConstant: 20)
                ])
                reactionsStackView.addArrangedSubview(imageView)
            }
        reactionsStackView.arrangedSubviews.reversed().forEach({reactionsStackView.bringSubviewToFront($0)})
        let reactionsCount: Int = reactions.reduce(0, {$0 + $1.value})
        countLabel.text = reactionsCount.counter()
    }
}
