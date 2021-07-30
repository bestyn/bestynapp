//
//  PhotoGridImageCell.swift
//  neighbourhood
//
//  Created by Artem Korzh on 07.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
protocol PhotoGridImageCellDelegate: class {
    func photoGridImageRemovePressed(cell: PhotoGridImageCell)
}

class PhotoGridImageCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var removeButton: UIButton!

    public var canBeRemoved = true
    public var imageURL: URL? {
        didSet { loadImage() }
    }

    public weak var delegate: PhotoGridImageCellDelegate?

    override func prepareForReuse() {
        imageView.image = nil
        removeButton.isHidden = true
        imageView.subviews.forEach { $0.removeFromSuperview() }
    }
    
    @IBAction func didPressRemove(_ sender: Any) {
        delegate?.photoGridImageRemovePressed(cell: self)
    }

    private func loadImage() {
        imageView.image = nil
        guard let imageURL = imageURL else {
            return
        }
        imageView.load(from: imageURL, withLoader: true) { [weak self] in
            self?.removeButton.isHidden = !(self?.canBeRemoved ?? false)
        }
    }
}
