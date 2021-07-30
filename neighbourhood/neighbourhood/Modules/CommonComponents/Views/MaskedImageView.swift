//
//  MaskedImageView.swift
//  neighbourhood
//
//  Created by Dioksa on 08.07.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

@IBDesignable
class MaskedImageView: UIView {

    @IBOutlet var imageContainerView: UIView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var maskPreviewView: UIView!

    @IBInspectable var image: UIImage? {
        didSet { setupImageView() }
    }

    @IBInspectable var maskHorizontalPadding: CGFloat = 40 {
        didSet { setupMask() }
    }

    @IBInspectable var maskProportions: CGFloat = 1 {
        didSet { setupMask() }
    }

    @IBInspectable var maskRounded: Bool = false {
        didSet { setupMask() }
    }

    private var holeRect: CGRect {
//        let holeWidth = maskPreviewView.bounds.width - 2 * maskHorizontalPadding
//        let holeHeight = holeWidth / maskProportions

        let holeWidth = bounds.width - 2 * maskHorizontalPadding
        let holeHeight = holeWidth / 1.6
        
        return CGRect(x: maskHorizontalPadding, y: (bounds.height - holeHeight) / 2, width: holeWidth, height: holeHeight)
    }

    public var resultImage: UIImage? {
        guard let image = imageContainerView.screenshot,
            let resultImage = image.crop(rect: holeRect) else {
                return nil
        }
        return resultImage
    }

    private var originCropParameters: CGRect?

    public var cropParameters: CGRect {
        get {
            let imageFrame = imageView.frame
            let x = (holeRect.minX - imageFrame.minX) / imageView.transform.a
            let y = (holeRect.minY - imageFrame.minY) / imageView.transform.a
            let height = holeRect.height / imageView.transform.a
            let width = holeRect.width / imageView.transform.a
            return CGRect(x: x, y: y, width: width, height: height)
        }

        set {
            self.originCropParameters = newValue
        }
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
        loadFromXib(R.nib.maskedImageView.name, contextOf: MaskedImageView.self)
        setupGestures()
    }

    override func draw(_ rect: CGRect) {
        setupMask()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let originCropParameters = originCropParameters else {
            return
        }
        self.originCropParameters = nil
        guard let size = imageView.image?.size else {
            return
        }
        let scale = holeRect.width / originCropParameters.width
        let source = CGRect(
            origin: CGPoint(x: bounds.midX - (size.width / 2), y: bounds.midY - size.height / 2),
            size: size)
        let destination = CGRect(
            origin: CGPoint(x: holeRect.minX - originCropParameters.minX * scale, y: holeRect.minY - originCropParameters.minY * scale),
            size: CGSize(width: size.width * scale, height: size.height * scale))
        imageView.transform = CGAffineTransform.identity
                        .translatedBy(x: destination.midX - source.midX, y: destination.midY - source.midY)
                        .scaledBy(x: destination.width / source.width, y: destination.height / source.height)
    }
}

extension MaskedImageView {

    private func setupImageView() {
        guard let image = image else {
            return
        }
        imageView.image = image
        imageView.frame.size = image.size
        let ratio = bounds.width / bounds.height
        let imageRatio = image.size.width / image.size.height
        let scale: CGFloat = {
            if  imageRatio > ratio {
                return bounds.width / image.size.width
            } else {
                return bounds.height / image.size.height
            }
        }()
        if originCropParameters == nil {
            imageView.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }

    private func setupMask() {
        let path = CGMutablePath()
        path.addRect(maskPreviewView.bounds)
        if maskRounded {
            path.addEllipse(in: holeRect)
        } else {
            path.addRoundedRect(in: holeRect, cornerWidth: 12, cornerHeight: 12)
        }
        let mask = CAShapeLayer()
        mask.path = path
        mask.fillRule = .evenOdd
        maskPreviewView.layer.mask = mask
    }

    private func setupGestures() {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panImageView(gestureRecognizer:)))
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinchImageView(gestureRecognizer:)))
        panGestureRecognizer.delegate = self
        pinchGestureRecognizer.delegate = self
        imageContainerView.addGestureRecognizer(panGestureRecognizer)
        imageContainerView.addGestureRecognizer(pinchGestureRecognizer)
    }

    @objc private func panImageView(gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: imageContainerView)
        imageView.center = CGPoint(x: imageView.center.x + translation.x, y: imageView.center.y + translation.y)
        gestureRecognizer.setTranslation(.zero, in: imageContainerView)
        checkImageOutOfMask()
    }

    @objc private func pinchImageView(gestureRecognizer: UIPinchGestureRecognizer) {
        imageView.transform = imageView.transform.scaledBy(x: gestureRecognizer.scale, y: gestureRecognizer.scale)
        gestureRecognizer.scale = 1
        checkImageOutOfMask()

    }

    private func checkImageOutOfMask() {
        var frame = imageView.frame
        let ratio = holeRect.width / holeRect.height
        let imageRatio = frame.width / frame.height
        if imageRatio <= ratio, frame.width < holeRect.width {
            let scale = holeRect.width / frame.width
            imageView.transform = imageView.transform.scaledBy(x: scale, y: scale)
        }
        if imageRatio > ratio, frame.height < holeRect.height {
            let scale = holeRect.height / frame.height
            imageView.transform = imageView.transform.scaledBy(x: scale, y: scale)
        }
        frame = imageView.frame
        var moveX: CGFloat = 0
        var moveY: CGFloat = 0
        if frame.minX > holeRect.minX {
            moveX = holeRect.minX - frame.minX
        }
        if frame.maxX < holeRect.maxX {
            moveX = holeRect.maxX - frame.maxX
        }

        if frame.minY > holeRect.minY {
            moveY = holeRect.minY - frame.minY
        }
        if frame.maxY < holeRect.maxY {
            moveY = holeRect.maxY - frame.maxY
        }

        imageView.center = CGPoint(x: imageView.center.x + moveX, y: imageView.center.y + moveY)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension MaskedImageView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
