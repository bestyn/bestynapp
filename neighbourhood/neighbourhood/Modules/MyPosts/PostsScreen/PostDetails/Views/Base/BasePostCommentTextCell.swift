//
//  BasePostCommentTextCell.swift
//  neighbourhood
//
//  Created by Artem Korzh on 04.09.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import ExpandableLabel

class BasePostCommentTextCell: BasePostCommentCell {

    @IBOutlet weak var chatMessageLabel: CustomExpandableLabel!

    public var expanded: Bool = false

    override func layoutSubviews() {
        super.layoutSubviews()
        chatMessageLabel.text = message?.text
    }


    override func setupSpecificViews() {
        chatMessageLabel.textColor = isIncome ? R.color.mainBlack() : .white
        chatMessageLabel.detectingTypes = [.links]
        chatMessageLabel.textReplacementType = .character
        chatMessageLabel.numberOfLines = 2
        let color = isIncome ? R.color.greyMedium()! : R.color.whiteTransparent()!
        chatMessageLabel.collapsedAttributedLink = NSAttributedString(
            string: "...\(R.string.localizable.viewAllTitle())",
            attributes: [.foregroundColor: color])
        chatMessageLabel.linkColor = color
        chatMessageLabel.delegate = self

        if let recognizers = chatMessageLabel.gestureRecognizers {
            for recognizer in recognizers where recognizer is UILongPressGestureRecognizer {
                recognizer.isEnabled = false
            }
        }
    }

    override func fillSpecificData(message: ChatMessageModel) {
        chatMessageLabel.collapsed = !expanded
        chatMessageLabel.text = message.text
    }
}

extension BasePostCommentTextCell: ExpandableTextViewDelegate {
    func expandableTextView(_ textView: ExpandableTextView, didChangeState isExpanded: Bool) {
        delegate?.cellNeedResize(cell: self)
    }
}

extension BasePostCommentTextCell: CustomExpandableLabelDelegate {

    func linkPressed(type: CustomExpandableLabel.DetectedLinkType) {
        switch type {
        case .link(let urlString):
            if let link = URL(string: urlString),
               UIApplication.shared.canOpenURL(link) {
                   UIApplication.shared.open(link)
               }
        case .profile(let profileId):
            delegate?.mentionSelected(profileId: profileId)
        case .hashtag:
            break
        }

    }

    func willExpandLabel(_ label: ExpandableLabel) {
        delegate?.cellNeedResize(cell: self)
    }

    func didExpandLabel(_ label: ExpandableLabel) {
        delegate?.cellNeedResize(cell: self)
    }

    func willCollapseLabel(_ label: ExpandableLabel) {

    }

    func didCollapseLabel(_ label: ExpandableLabel) {

    }


}

