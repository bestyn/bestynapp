//
//  MediaPostCell.swift
//  neighbourhood
//
//  Created by Artem Korzh on 21.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

class MediaPostCell: BasePostCell {

    @IBOutlet weak var photoImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupImageView()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.image = R.image.image_placeholder()
    }

    private func setupImageView() {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapImage))
        photoImageView.addGestureRecognizer(tapRecognizer)
        photoImageView.isUserInteractionEnabled = true
    }

    @objc private func didTapImage() {
        guard let media = post?.media?.first else {
            return
        }
        cellDelegate?.openMedia(media)
    }

    override func fillAdditionalInfo(from post: PostModel) {
        if let url = post.media?.first?.formatted?.medium {
            photoImageView.load(from: url) {}
        }
    }
}
