//
//  BusinessCollectionViewImageCell.swift
//  neighbourhood
//
//  Created by Dioksa on 15.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

protocol ImageCollectionUpdatableDelegate: AnyObject {
    func remove(image: UserAvatar)
}

final class BusinessCollectionViewImageCell: UICollectionViewCell {
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var removeButton: UIButton!
    
    private var addedImage: UserAvatar?
    
    weak var delegate: ImageCollectionUpdatableDelegate?
    
    @IBAction private func removeImageButton(_ sender: UIButton) {
        guard let image = addedImage else { return }
        delegate?.remove(image: image)
    }
    
    public func updateImage(with image: UserAvatar) {
        addedImage = image
        imageView.load(from: image.origin) {}
    }
    
    public func hideRemoveButton() {
        removeButton.isHidden = true
    }
}
