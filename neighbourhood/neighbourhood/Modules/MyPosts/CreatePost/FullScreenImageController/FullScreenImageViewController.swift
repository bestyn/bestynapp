//
//  FullScreenImageViewController.swift
//  neighbourhood
//
//  Created by Dioksa on 25.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import Kingfisher

final class FullScreenImageViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var imageContainerView: UIView!

    private var selectedImage: UIImage?
    
    var imageUrl: URL?
    var isReadyToScale = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let selectedImage = selectedImage {
            imageView.image = selectedImage
        } else if let imageUrl = imageUrl {
            imageView.image = UIImage.colored(size: view.bounds.size)
            imageView.load(from: imageUrl, withLoader: true) { [weak self] in
                if self?.isReadyToScale == true {
                    self?.setupImageView()
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupImageView()
        isReadyToScale = true
    }

    private func setupImageView() {
        guard let image = imageView.image else {
            return
        }
        let screenBounds = UIScreen.main.bounds
        setupGestures()
        let ratio = screenBounds.width / screenBounds.height
        let imageRatio = image.size.width / image.size.height
        let scale: CGFloat = {
            if  imageRatio > ratio {
                return screenBounds.width / image.size.width
            } else {
                return screenBounds.height / image.size.height
            }
        }()
        imageView.transform = .init(scaleX: scale, y: scale)
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
        let ratio = view.bounds.width / view.bounds.height
        let imageRatio = frame.width / frame.height
        if imageRatio > ratio, frame.width <= view.bounds.width {
            let scale = view.bounds.width / frame.width
            imageView.transform = imageView.transform.scaledBy(x: scale, y: scale)
            imageView.center = view.center
        }

        if imageRatio <= ratio, frame.height <= view.bounds.height {
            let scale = view.bounds.height / frame.height
            imageView.transform = imageView.transform.scaledBy(x: scale, y: scale)
            imageView.center = view.center
        }

        frame = imageView.frame

        if imageRatio > ratio {
            if frame.height < view.bounds.height {
                imageView.center.y = view.center.y
            }
        }

        if imageRatio > ratio || frame.width > view.bounds.width {
            if frame.minX > view.bounds.minX {
                imageView.center.x += (view.bounds.minX - frame.minX)
            }
            if frame.maxX < view.bounds.maxX {
                imageView.center.x += (view.bounds.maxX - frame.maxX)
            }
        }

        if imageRatio <= ratio{
            if frame.width < view.bounds.width {
                imageView.center.x = view.center.x
            }
        }

        if imageRatio <= ratio || frame.height > view.bounds.height {
            if frame.minY > view.bounds.minY {
                imageView.center.y += (view.bounds.minY - frame.minY)
            }
            if frame.maxY < view.bounds.maxY {
                imageView.center.y += (view.bounds.maxY - frame.maxY)
            }
        }

    }
    
    func imageToZoom(image: UIImage?) {
        selectedImage = image
    }


    @IBAction private func dismissButtonDidTap(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func didTapDownload(_ sender: Any) {
        guard let image = imageView.image else {
            return
        }
        DownloadService.saveImageToGallery(image: image)
    }
}


// MARK: - UIGestureRecognizerDelegate

extension FullScreenImageViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
