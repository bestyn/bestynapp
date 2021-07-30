//
//  BaseChatMediaCell.swift
//  neighbourhood
//
//  Created by Artem Korzh on 01.09.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import AVKit

class BaseChatMediaCell: BaseChatTextCell {
    @IBOutlet private weak var attachImageView: UIImageView!

    private lazy var tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(attachmentDidTap))

    private lazy var playIcon: UIImageView = {
        let playIcon = UIImageView(image: R.image.play_video_icon())
        playIcon.isHidden = true
        playIcon.translatesAutoresizingMaskIntoConstraints = false
        self.attachImageView.addSubview(playIcon)
        playIcon.widthAnchor.constraint(equalToConstant: 36).isActive = true
        playIcon.heightAnchor.constraint(equalToConstant: 36).isActive = true
        playIcon.centerYAnchor.constraint(equalTo: self.attachImageView.centerYAnchor).isActive = true
        playIcon.centerXAnchor.constraint(equalTo: self.attachImageView.centerXAnchor).isActive = true
        self.attachImageView.bringSubviewToFront(playIcon)
        return playIcon
    }()

    weak var mediaDelegate: ChatAttachmentDelegate?

    override func setupSpecificView() {
        super.setupSpecificView()
        setImageCorners()
        attachImageView.addGestureRecognizer(tapRecognizer)
    }

    override func resetView() {
        super.resetView()
        attachImageView.image = nil
        playIcon.isHidden = true
    }

    override func fillSpecificData(from message: PrivateChatMessageModel) {
        super.fillSpecificData(from: message)

        chatMessageTextView.isHidden = message.text.isEmpty
        voiceButton.isHidden = message.text.isEmpty
        setImageCorners(all: message.text.isEmpty)

        guard let attachment = message.attachment else {
            return
        }

        if attachment.type == .image {
            attachImageView.image = R.image.image_placeholder()
            guard let url = attachment.formatted?.medium  else {
                return
            }
            UIImage.load(from: url) { [weak self] (image) in
                guard let image = image, self?.message?.id == message.id else {
                    return
                }
                DispatchQueue.main.async {
                    self?.attachImageView.image = image
                    self?.layoutSubviews()
                }
            }
        } else {
            attachImageView.image = R.image.video_placeholder()
            playIcon.isHidden = false
            if let thumbnail = attachment.formatted?.thumbnail {
                UIImage.load(from: thumbnail) { [weak self] (image) in
                    guard let image = image, self?.message?.id == message.id else {
                        return
                    }
                    DispatchQueue.main.async {
                        self?.attachImageView.image = image
                        self?.layoutSubviews()
                    }
                }
            } else {
                setVideoThumbnail(videoURL: attachment.formatted?.preview ?? attachment.origin)
            }
        }
    }

    private func setImageCorners(all: Bool = false) {
        let corners: UIRectCorner = all ? .allCorners : [.bottomRight, .bottomLeft]
        attachImageView.roundCorners(
            corners: corners,
            radius: GlobalConstants.Dimensions.messageViewRadius)
    }

    private func setVideoThumbnail(videoURL: URL) {
        let asset = AVURLAsset(url: videoURL, options: nil)
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        imgGenerator.appliesPreferredTrackTransform = true
        let time = CMTimeMake(value: 0, timescale: 1)

        imgGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { (_, cgImage, _, result, error) in
            if let error = error {
                print(error)
                return
            }
            guard let cgImage = cgImage,
                  self.message?.attachment?.formatted?.preview == videoURL ||
            self.message?.attachment?.origin == videoURL  else {
                return
            }
            DispatchQueue.main.async {
                let uiImage = UIImage(cgImage: cgImage)
                self.attachImageView.image = uiImage
                self.layoutSubviews()
            }
        }
    }


    @objc private func attachmentDidTap() {
        guard let attachment = message?.attachment else {
            return
        }
        mediaDelegate?.mediaDidSelected(media: attachment)
    }

}
