//
//  HighlightTextView.swift
//  neighbourhood
//
//  Created by Artem Korzh on 11.01.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import UIKit

class HighlightTextView: UITextView {

    private let highlightLayoutManager = HighlightLayoutManager()
    public var color: UIColor {
        set { highlightLayoutManager.color = newValue }
        get { highlightLayoutManager.color }
    }

    public var highlightCornerRadius: Int {
        set { highlightLayoutManager.highlightCornerRadius = newValue }
        get { highlightLayoutManager.highlightCornerRadius }
    }

    init() {
        let storage = NSTextStorage()
        let textFrame = CGSize.zero
        let containerSize = CGSize(width: textFrame.width - 20, height: .greatestFiniteMagnitude)
        let container = NSTextContainer(size: containerSize)
        highlightLayoutManager.addTextContainer(container)
        storage.addLayoutManager(highlightLayoutManager)
        super.init(frame: .zero, textContainer: container)
        backgroundColor = .clear
        textContainerInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    }

    convenience init(textEditorEntity: TextEditorEntity) {
        self.init()
        text = textEditorEntity.text
        font = textEditorEntity.font
        textColor = textEditorEntity.textColor
        color = textEditorEntity.highlightColor
        highlightCornerRadius = textEditorEntity.highlightRadius
        textAlignment = textEditorEntity.alignment
        contentOffset = .zero
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setSizeInScreen() {
        isScrollEnabled = false
        var textSize = sizeThatFits(CGSize(width: UIScreen.main.bounds.width - 70, height: .greatestFiniteMagnitude))
        textSize.width = UIScreen.main.bounds.width - 70
        bounds = CGRect(origin: .zero, size: textSize)
    }
}


// MARK: - HighlightLayoutManager

class HighlightLayoutManager: NSLayoutManager {

    public var color: UIColor = .clear
    public var highlightCornerRadius: Int = 50

    private var path: UIBezierPath!

    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)
        let range = characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        let gRange = glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        var rects: [CGRect] = []
        path = UIBezierPath()
        enumerateLineFragments(forGlyphRange: gRange) { (rect, usedRect, _, range, _) in
            rects.append(usedRect)
        }
        for (index, rect) in rects.enumerated() {
            let finalRect = CGRect(
                x: rect.origin.x,
                y: rect.origin.y + origin.y,
                width: rect.width + 20,
                height: rect.height)

            let radius = (finalRect.height / 2) * CGFloat(highlightCornerRadius) / 100
            path.append(
                .init(
                    roundedRect: finalRect,
                    byRoundingCorners: .allCorners,
                    cornerRadii: CGSize(width: radius, height: radius)
                )
            )
        }
        color.set()
        if let context = UIGraphicsGetCurrentContext() {
            context.setAllowsAntialiasing(true)
            context.setShouldAntialias(true)
            context.addPath(path.cgPath)
            context.drawPath(using: .fillStroke)
        }
    }
}
