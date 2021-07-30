//
//  VideoSlider.swift
//  neighbourhood
//
//  Created by Artem Korzh on 01.12.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import AVFoundation

private enum Defaults {
    static let highlightColor: UIColor = R.color.accentRed()!.withAlphaComponent(0.5)
    static let disabledHighlightColor: UIColor = .clear
    static let handlesColor: UIColor = R.color.accentRed()!
    static let disabledHandlesColor: UIColor = .init(red: 0.092, green: 0.092, blue: 0.092, alpha: 1)
}

protocol VideoSliderDelegate {
    func rangeChanged(_ range: ClosedRange<Double>)
    func frameChanged(second: Double)
    func dragStarted()
    func dragEnded()
}

struct VideoSliderParams {
    let assetParams: VideoAssetParams
    let range: ClosedRange<Double>?
}

class VideoSlider: UIView {

    enum Mode {
        case rangeSelection
        case frameSelection
    }

    @IBOutlet weak var framesStackView: UIStackView!

    @IBOutlet weak var leftHandleView: UIView!
    @IBOutlet weak var leftHandleBackground: UIView!
    @IBOutlet weak var leftHandleDragView: UIView!

    @IBOutlet weak var rightHandleView: UIView!
    @IBOutlet weak var rightHandleBackground: UIView!
    @IBOutlet weak var rightHandleDragView: UIView!

    @IBOutlet weak var frameHandleView: UIView!
    @IBOutlet weak var frameHandleDragView: UIView!

    @IBOutlet weak var highlightView: UIView!

    @IBOutlet weak var framesHolderView: UIView!
    @IBOutlet weak var timeView: UIView!
    @IBOutlet weak var rightTimeLabel: UILabel!
    @IBOutlet weak var leftTimeLabel: UILabel!
    @IBOutlet weak var framesScrollView: UIScrollView!

    private var viewsIsSet = false
    private var pps: CGFloat = .zero
    private var isScrolling = false

    public var mode: Mode = .rangeSelection {
        didSet { updateModeLayout() }
    }

    public var params: VideoSliderParams! {
        didSet {
            localRange = params.range
            if viewsIsSet {
                updateSlider()
                moveRangeHandles()
                updateTimeValues()
            }
        }
    }

    public var frameTime: CMTime = .zero {
        didSet { moveFrameHandle() }
    }

    private var localRange: ClosedRange<Double>!

    public var range: ClosedRange<Double> { localRange }

    public var delegate: VideoSliderDelegate?
    public var stepInSeconds: Double?
    public var withTime: Bool = true {
        didSet {
            timeView.isHidden = !withTime
            setupViews()
        }
    }
    private var isDragging: Bool = false {
        didSet { isDragging ? delegate?.dragStarted() : delegate?.dragEnded() }
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
        loadFromXib(R.nib.videoSlider.name, contextOf: VideoSlider.self)
        frameHandleView.frame = CGRect(origin: CGPoint(x: leftHandleView.frame.maxX, y: 0), size: frameHandleView.frame.size)
        setupViews()
        updateModeLayout()
        setupGestures()
        framesScrollView.delegate = self
        self.backgroundColor = .clear
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !viewsIsSet {
            setupViews()
            updateSlider()
            viewsIsSet = true
            moveRangeHandles()
            updateTimeValues()
        }
        updateModeLayout()
    }
}

extension VideoSlider {

    private func setupViews() {
        let height = frame.height - (withTime ? 22 : 0)
        leftHandleView.frame = CGRect(
            x: 0,
            y: 4,
            width: 8,
            height: height - 8)
        rightHandleView.frame = CGRect(
            x: frame.width - 8,
            y: 4,
            width: 8,
            height: height - 8)
        frameHandleView.frame = CGRect(
            x: leftHandleView.frame.maxX,
            y: 0,
            width: 0.01,
            height: height)
        updateHighlightViewSize()
    }

    private func setupGestures() {
        let leftGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(leftHandleMoveHandler(recognizer:)))
        leftHandleDragView.addGestureRecognizer(leftGestureRecognizer)
        let rightGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(rightHandleMoveHandler(recognizer:)))
        rightHandleDragView.addGestureRecognizer(rightGestureRecognizer)
        let frameGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(frameHandleMoveHandler(recognizer:)))
        frameHandleDragView.addGestureRecognizer(frameGestureRecognizer)
        [leftHandleDragView, rightHandleDragView, frameHandleDragView].forEach({$0?.isUserInteractionEnabled = true})
    }

    @objc private func leftHandleMoveHandler(recognizer: UIPanGestureRecognizer) {
        if mode == .frameSelection {
            return
        }
        if recognizer.state == .began { isDragging = true }
        if recognizer.state == .ended { isDragging = false }
        moveHandler(
            handler: leftHandleView,
            recognizer: recognizer,
            min: max(rightHandleView.frame.minX - 60 * pps - leftHandleView.frame.width  , 0),
            max: rightHandleView.frame.minX - pps - leftHandleView.frame.width)
        rangeChanged()
        updateHighlightViewSize()
        snapFrameHandler(to: .left)
    }

    @objc private func rightHandleMoveHandler(recognizer: UIPanGestureRecognizer) {
        if mode == .frameSelection {
            return
        }
        if recognizer.state == .began { isDragging = true }
        if recognizer.state == .ended { isDragging = false }
        moveHandler(
            handler: rightHandleView,
            recognizer: recognizer,
            min: leftHandleView.frame.maxX + pps,
            max: min(leftHandleView.frame.maxX + 60 * pps, self.frame.width - rightHandleView.frame.width))
        rangeChanged()
        updateHighlightViewSize()
        snapFrameHandler(to: .right)
    }

    @objc private func frameHandleMoveHandler(recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .began { isDragging = true }
        if recognizer.state == .ended { isDragging = false }
        moveHandler(
            handler: frameHandleView,
            recognizer: recognizer,
            min: leftHandleView.frame.maxX,
            max: rightHandleView.frame.minX - frameHandleView.bounds.width)
        frameChanged()
    }

    private func moveHandler(handler: UIView, recognizer: UIPanGestureRecognizer, min: CGFloat, max: CGFloat) {
        print("moving handle")
        let translation = recognizer.translation(in: self)
        var finalPosition = handler.frame.minX + translation.x
        if finalPosition < min {
            finalPosition = min
        } else if finalPosition > max {
            finalPosition = max
        }
        let move = finalPosition - handler.frame.minX
        print(finalPosition, move)
        handler.center = handler.center.applying(CGAffineTransform(translationX: move, y: 0))
        recognizer.setTranslation(.zero, in: self)
    }

    private enum HandleSide {
        case right, left
    }

    private func snapFrameHandler(to side: HandleSide) {
        let finalPosition: CGFloat
        switch side {
        case .left:
            finalPosition = leftHandleView.frame.maxX + frameHandleView.frame.width / 2
        case .right:
            finalPosition = rightHandleView.frame.minX - frameHandleView.frame.width / 2
        }
        let move = finalPosition - frameHandleView.center.x
        frameHandleView.center = frameHandleView.center.applying(CGAffineTransform(translationX: move, y: 0))
        frameChanged()
    }

    private func updateHighlightViewSize() {
        highlightView.frame = CGRect(
            x: leftHandleView.frame.maxX,
            y: leftHandleView.frame.minY,
            width: rightHandleView.frame.minX - leftHandleView.frame.maxX,
            height: rightHandleView.frame.height)
    }

}

extension VideoSlider {
    private func updateSlider() {
        guard let params = params else {
            return
        }
        let assetParams = params.assetParams
        framesScrollView.contentOffset = .zero
        if localRange == nil {
            localRange = 0...assetParams.asset.duration.seconds
        }
        let frameWidth = framesScrollView.bounds.height * 9 / 16
        let minFramesCount: CGFloat = ceil((frame.width - 16) / frameWidth)
        if minFramesCount == .infinity {
            return
        }
        let framesCount: Int32
        if assetParams.asset.duration.seconds > 60 {
            let secondPerFrame = 60 / minFramesCount
            framesCount = Int32(assetParams.asset.duration.seconds / Double(secondPerFrame))
            framesScrollView.isScrollEnabled = true
        } else {
            framesCount = Int32(minFramesCount)
            framesScrollView.isScrollEnabled = false
        }

        pps = (frame.width - 16) / CGFloat(min(assetParams.asset.duration.seconds, 60))
        framesStackView.arrangedSubviews.forEach({$0.removeFromSuperview()})
        FrameGenerator().multiple(from: assetParams , framesCount: framesCount) { [weak self] (images) in
            for image in images {
                let imageView = UIImageView(image: image)
                imageView.clipsToBounds = true
                imageView.contentMode = .scaleAspectFill
                NSLayoutConstraint.activate([
                    imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: 9/16)
                ])
                self?.framesStackView.addArrangedSubview(imageView)
            }
        }
    }

    private func updateModeLayout() {
        highlightView.backgroundColor = mode == .rangeSelection ? Defaults.highlightColor : Defaults.disabledHighlightColor
        [leftHandleBackground, rightHandleBackground]
            .forEach({$0.backgroundColor = mode == .rangeSelection ? Defaults.handlesColor : Defaults.disabledHandlesColor})
        var frame = frameHandleView.frame
        frame.size.width = mode == .frameSelection ? self.bounds.height * 9 / 16 : 4
        frameHandleView.frame = frame
        leftHandleBackground.roundCorners(corners: [.topLeft, .bottomLeft], radius: 4)
        rightHandleBackground.roundCorners(corners: [.topRight, .bottomRight], radius: 4)

    }

    private func moveFrameHandle() {
        let position = 4 + CGFloat(frameTime.seconds) * pps - framesScrollView.contentOffset.x
        frameHandleView.center = frameHandleView.center.applying(.init(translationX: position - frameHandleView.frame.minX, y: 0))
    }

    private func moveRangeHandles() {
        var fromPosition = CGFloat(range.lowerBound) * pps + 4
        var tillPosition = CGFloat(range.upperBound) * pps + 12
        if tillPosition > frame.size.width - 4 {
            framesScrollView.contentOffset = CGPoint(x: min(-(CGFloat(range.lowerBound) * pps), 0), y: 0)
        }
        fromPosition += framesScrollView.contentOffset.x
        tillPosition += framesScrollView.contentOffset.x
        leftHandleView.center = CGPoint(x: fromPosition, y: leftHandleView.center.y)
        rightHandleView.center = CGPoint(x: tillPosition, y: rightHandleView.center.y)
        updateHighlightViewSize()
        snapFrameHandler(to: .left)
    }

    private func frameChanged() {
        let seconds = Double((frameHandleView.center.x + framesScrollView.contentOffset.x) / pps)
        delegate?.frameChanged(second: seconds)
    }

    private func rangeChanged(withSnap: Bool = true) {
        let fromSeconds = Double((leftHandleView.frame.maxX - 8 + framesScrollView.contentOffset.x) / pps)
        let tillSeconds = Double((rightHandleView.frame.minX - 8 + framesScrollView.contentOffset.x) / pps)
        localRange = fromSeconds...tillSeconds
        delegate?.rangeChanged(localRange)
        if withSnap {
            snapFrameHandler(to: .left)
        }
        updateTimeValues()
    }

    private func updateTimeValues() {
        guard localRange != nil else {
            return
        }
        leftTimeLabel.text = String(format: "%.1fs", localRange.lowerBound)
        rightTimeLabel.text = String(format: "%.1fs", localRange.upperBound)
    }
}


extension VideoSlider: UIScrollViewDelegate {

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.dragStarted()
        isScrolling = true
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            delegate?.dragEnded()
            isScrolling = false
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        delegate?.dragEnded()
        isScrolling = false
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isScrolling {
            rangeChanged(withSnap: false)
            frameChanged()
            updateTimeValues()
        }
    }
}
