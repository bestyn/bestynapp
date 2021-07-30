//
//  BusinessCollectionViewImageCell.swift
//  neighbourhood
//
//  Created by Dioksa on 15.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

protocol ImageCollectionUpdatableDelegate: AnyObject {
    func remove(image: ImageModel)
    func openFullScreen(_ image: ImageModel)
}

final class BusinessCollectionViewImageCell: UICollectionViewCell {
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var removeButton: UIButton!
    @IBOutlet private weak var spinner: UIActivityIndicatorView!
    
    private var addedImage: ImageModel?
    private let imageLoader = ImageViewLoader()
    
    weak var delegate: ImageCollectionUpdatableDelegate?
    private lazy var gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
    
    override func awakeFromNib() {
        super.awakeFromNib()
        spinner.startAnimating()
        imageView.addGestureRecognizer(gestureRecognizer)
    }

    @IBAction private func removeImageButton(_ sender: UIButton) {
        guard let image = addedImage else { return }
        delegate?.remove(image: image)
    }
    
    @objc private func imageTapped() {
        guard let imageToPresent = addedImage else { return }
        delegate?.openFullScreen(imageToPresent)
    }
    
    public func updateImage(with image: ImageModel) {
        addedImage = image
        imageView.load(from: image.formatted?.medium ?? image.origin) {
            self.spinner.stopAnimating()
        }
    }
    
    public func hideRemoveButton() {
        removeButton.isHidden = true
    }
}
