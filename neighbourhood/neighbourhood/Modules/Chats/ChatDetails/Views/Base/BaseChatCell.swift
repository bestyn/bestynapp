//
//  BaseChatCell.swift
//  neighbourhood
//
//  Created by Artem Korzh on 01.09.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

protocol OwnerDependantCell {
    var isIncome: Bool {get}
}

class BaseChatCell: UITableViewCell, OwnerDependantCell {

    @IBOutlet weak var chatBackgroundView: UIView!
    @IBOutlet private weak var messagDateLabel: UILabel!
    @IBOutlet private weak var editLabel: UILabel!

    public var message: PrivateChatMessageModel? {
        didSet { fillData() }
    }

    var isIncome: Bool { true }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        resetView()
    }

    private func fillData() {
        guard let message = message else {
            return
        }
        messagDateLabel.text = message.createdAt.timeString
        editLabel?.isHidden = message.createdAt == message.updatedAt
        fillSpecificData(from: message)
    }

    private func setupView() {
        editLabel?.text = "\u{2022} \(R.string.localizable.editedTitle())"
        selectionStyle = .none
        setupOwnerDependantView()
        setupSpecificView()
    }

    private func setupOwnerDependantView() {
        chatBackgroundView.cornerRadius = GlobalConstants.Dimensions.messageViewRadius
    }

    func fillSpecificData(from message: PrivateChatMessageModel) {
        fatalError("Method not defined")
    }

    func resetView() {}

    func setupSpecificView() {}
}
