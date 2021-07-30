//
//  PostTypeSelectorViewController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 16.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

protocol PostSelectorDelegate: class {
    func postTypeDidSelected(_ type: TypeOfPost)
}

class PostTypeSelectorViewController: UIViewController, BottomMenuPresentable {

    @IBOutlet weak var createPostLabel: UILabel!
    @IBOutlet weak var buttonsStackView: UIStackView!
    @IBOutlet weak var containerView: UIView!

    var transitionManager: BottomMenuPresentationManager! = .init()
    var presentedViewHeight: CGFloat { return containerView.bounds.height }

    private var availableTypes: [TypeOfPost] {
        var types: [TypeOfPost] = [.news, .event, .crime, .general]
        if ArchiveService.shared.currentProfile?.type == .business {
            types.insert(.offer, at: 0)
        }
        return types
    }

    private weak var delegate: PostSelectorDelegate?

    init(delegate: PostSelectorDelegate) {
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setTitles()
        setButtons()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preferredContentSize = containerView.bounds.size
    }
}

// MARK: - Private functions

extension PostTypeSelectorViewController {
    private func setTitles() {
        createPostLabel.text = R.string.localizable.createPost()
    }

    private func setButtons() {
        availableTypes.forEach { (type) in
            let button = UIButton()
            button.backgroundColor = .white
            button.contentHorizontalAlignment = .leading
            button.contentEdgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
            button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
            button.titleLabel?.font = R.font.poppinsMedium(size: 15)
            button.setTitleColor(R.color.mainBlack(), for: .normal)
            button.setImage(type.icon, for: .normal)
            button.setTitle(type.title, for: .normal)
            button.addTarget(self, action: #selector(didTapType(sender:)), for: .touchUpInside)
            button.heightAnchor.constraint(equalToConstant: 60).isActive = true
            buttonsStackView.addArrangedSubview(button)
        }
        buttonsStackView.setNeedsLayout()
        print(buttonsStackView.bounds.size)
    }

    @objc private func didTapType(sender: UIButton) {
        guard let index = buttonsStackView.arrangedSubviews.firstIndex(of: sender) else {
            return
        }
        let type = availableTypes[index]
        dismiss(animated: true) {
            self.delegate?.postTypeDidSelected(type)
        }
    }
}
