//
//  CreateStoryViewModel.swift
//  neighbourhood
//
//  Created by Artem Korzh on 27.11.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class CreateStoryViewModel: BaseStoryRecordViewModel {

    let durations: [Double] = [15, 30, 45, 60]
    private var mediaSequence: AsyncSequence<GallerySelectionEntity>!

    @SingleEventObservable private(set) var gallerySelected: Bool?
    @SingleEventObservable private(set) var galleryProcessing: Bool = false

    override init() {
        super.init()
        storyCreator.setMode(.recorded)
        maxDuration = durations[durations.count - 1]
        maxLeftDuration = maxDuration
    }
}

// MARK: - Public methods

extension CreateStoryViewModel {

    public func selectMaxDuration(duration: Double) {
        self.maxDuration = duration
        self.maxLeftDuration = duration - totalRecordedDuration
    }
}

// MARK: - GallerySelectorDelegate

extension CreateStoryViewModel: GallerySelectorDelegate {
    func mediaSelected(entities: [GallerySelectionEntity]) {
        galleryProcessing = true
        storyCreator.setMode(.gallery)
        mediaSequence = AsyncSequence(originalSequence: entities)
        mediaSequence.execForEach { [weak self] (entity, next) in
            switch entity {
            case .image(let image):
                self?.storyCreator.addStoredImage(image: image) { error in
                    if let error = error {
                        Toast.show(message: error.localizedDescription)
                    }
                    next()
                }
            case .video(let video):
                self?.storyCreator.addStoredVideo(asset: video)
                next()
            }
        } completion: { [weak self] in
            self?.galleryProcessing = false
            if self?.storyCreator.resultClipParams != nil {
                self?.gallerySelected = true
            }
        }
    }

    func canSelectMore(mediaType: GallerySelectorMediaType, imagesSelected: Int, videosSelected: Int) -> Bool {
        if imagesSelected + videosSelected < 30 {
            return true
        }
        Toast.show(message: R.string.localizable.maxMediaSelected())
        return false
    }
}
