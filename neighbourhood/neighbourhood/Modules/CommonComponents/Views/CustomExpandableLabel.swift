//
//  CustomExpandableLabel.swift
//  neighbourhood
//
//  Created by Artem Korzh on 13.11.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

protocol CustomExpandableLabelDelegate: ExpandableLabelDelegate {
    func linkPressed(type: CustomExpandableLabel.DetectedLinkType)
}

class CustomExpandableLabel: ExpandableLabel {

    enum DetectedLinkType {
        case hashtag(String)
        case link(String)
        case profile(Int)
    }

    private var detectedLinks: [NSRange: DetectedLinkType] = [:]
    var linkColor: UIColor = R.color.blueButton()!
    var linkFont: UIFont?

    var detectingTypes: [String.LinkType] = [.links, .hashtags]

    var highlightedAttributedText: NSAttributedString!

    open override var text: String? {
        set(text) {
            if let text = text {
                self.highlightedAttributedText = nil
                self.attributedText = highlightedAttributedString(text)
            } else {
                self.attributedText = nil
                self.highlightedAttributedText = nil
            }
        }
        get {
            return self.attributedText?.string
        }
    }

    private func highlightedAttributedString(_ text: String) -> NSAttributedString {
        if let highlightedAttributedText = highlightedAttributedText {
            return highlightedAttributedText
        }
        self.detectedLinks = [:]
        var textToShow = text
        while let mention = textToShow.linksRanges(types: [.rawMentions]).sorted(by: {$0.range.lowerBound < $1.range.lowerBound}).first {
            var link = mention.link
            link.remove(at: link.index(link.endIndex, offsetBy: -1))
            link.remove(at: link.startIndex)
            let values = link.split(separator: "|")
            if let id = Int(values.last!) {
                let name = "@\(link.replacingOccurrences(of: "|\(id)", with: ""))"
                textToShow = (textToShow as NSString).replacingCharacters(in: mention.range, with: name)
                let range = (textToShow as NSString).range(of: name)
                detectedLinks[range] = .profile(id)
            }
        }

        let attributedString = NSMutableAttributedString(string: textToShow)
        for range in detectedLinks.keys {
            attributedString.setAttributes([
                .foregroundColor: linkColor,
                .font: linkFont ?? font,
            ], range: range)
        }
        let linksResults = textToShow.linksRanges(types: detectingTypes)
        if linksResults.count == 0 {
            return attributedString
        }

        for linkRange in linksResults {
            switch linkRange.type {
            case .hashtags:
                detectedLinks[linkRange.range] = .hashtag(linkRange.link)
            case .links:
                detectedLinks[linkRange.range] = .link(linkRange.link)
            default:
                break
            }
            attributedString.setAttributes([
                .foregroundColor: linkColor,
                .font: linkFont ?? font,
            ], range: linkRange.range)
        }
        self.highlightedAttributedText = attributedString
        return attributedString
    }

    override func getBaseAttributedText(text: NSAttributedString) -> NSAttributedString {
        return highlightedAttributedText ?? highlightedAttributedString(text.string)
//        return text
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let locationOfTouch = touches.first else {
            return
        }
        if let linkRange = collapsed ? collapsedLinkTextRange : expandedLinkTextRange,
           check(touch: locationOfTouch, isInRange: linkRange) {
            return
        }
        for range in detectedLinks.keys {
            if check(touch: locationOfTouch, isInRange: range),
               let type = detectedLinks[range] {
                (delegate as? CustomExpandableLabelDelegate)?.linkPressed(type: type)
                return
            }
        }
    }
}
