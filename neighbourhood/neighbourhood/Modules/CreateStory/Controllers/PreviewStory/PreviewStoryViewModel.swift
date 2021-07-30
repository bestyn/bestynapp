//
//  PreviewStoryViewModel.swift
//  neighbourhood
//
//  Created by Artem Korzh on 01.12.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import AVFoundation

class PreviewStoryViewModel {

    var storyCreator: StoryCreator { .shared }

    @Observable private(set) var assetParams: VideoAssetParams!
    @Observable private(set) var texts: [StoryCreator.TextEntity] = []
    @Observable private(set) var isMuted = false
    @SingleEventObservable private(set) var gallerySelected = false
    @Observable private(set) var audioMix: AVAudioMix?
    public var isGalleryAvailable: Bool { storyCreator.mode == .gallery }
    public var isAdjustClipAvailable: Bool { [.recorded, .gallery].contains(storyCreator.mode) }
    public var isTextStoryMode: Bool { storyCreator.mode == .text }
    public var textBackgroundLayer: CAGradientLayer { storyCreator.textBackgroundLayer }
    public let textDurations: [Double] = [15, 30, 45, 60]

    private var editingTextEntity: StoryCreator.TextEntity?

    init() {
        assetParams = storyCreator.resultClipParams
    }

    public func toggleMute() {
        isMuted.toggle()
        storyCreator.setShouldMute(isMuted)
    }

    public func cancelCreation() {
        storyCreator.setMode(.recorded)
    }

    public func addText(entity: TextEditorEntity) {
        if var editingTextEntity = editingTextEntity {
            editingTextEntity.editorEntity = entity
            storyCreator.updateTextEntity(for: editingTextEntity)
            self.editingTextEntity = nil
        } else {
            storyCreator.addText(entity: entity)
        }
        texts = storyCreator.texts
    }

    public func updateTextTransform(entity: StoryCreator.TextEntity, transform: CGAffineTransform) {
        var entity = entity
        entity.transform = transform
        storyCreator.updateTextEntity(for: entity)
        texts = storyCreator.texts
    }

    public func editText(entity: StoryCreator.TextEntity) {
        editingTextEntity = entity
    }

    public func removeText(entity: StoryCreator.TextEntity) {
        storyCreator.removeText(entity: entity)
        editingTextEntity = nil
        texts = storyCreator.texts
    }

    public func changeGradient(_ gradient: StoryGradient) {
        storyCreator.changeTextBackgroundGradient(gradient)
    }

    public func setTextStoryDuration(_ duration: Double) {
        storyCreator.changeTextStoryDuration(seconds: duration)
        assetParams = storyCreator.resultClipParams
        texts = storyCreator.texts
    }

    public func selectTrack(track: AudioTrackModel) {
        storyCreator.setAudioTrack(track: track)
        self.assetParams = self.storyCreator.resultClipParams
    }

    public func setTrackTime(start: Double) {
        storyCreator.setAudioStart(start)
        self.assetParams = self.storyCreator.editingClipContent.assetParams
    }

    public func beginEdit() {
        storyCreator.startEditing()
        self.assetParams = self.storyCreator.editingClipContent.assetParams
    }

    public func confirmEdit() {
        storyCreator.saveEdit()
        self.assetParams = self.storyCreator.resultClipParams
    }

    public func cancelEdit() {
        storyCreator.cancelEditing()
        self.assetParams = self.storyCreator.resultClipParams
    }
}

// MARK: - ClipAdjustmentViewControllerDelegate

extension PreviewStoryViewModel: ClipAdjustmentViewControllerDelegate {
    func adjustmentsComplete() {
        assetParams = storyCreator.resultClipParams
        texts = storyCreator.texts
    }
}

// MARK: - GallerySelectorDelegate

extension PreviewStoryViewModel: GallerySelectorDelegate {
    func mediaSelected(entities: [GallerySelectionEntity]) {
        storyCreator.setMode(.gallery)
        let group = DispatchGroup()
        entities.forEach { (entity) in
            group.enter()
            switch entity {
            case .image(let image):
                storyCreator.addStoredImage(image: image) { error in
                    if let error = error {
                        Toast.show(message: error.localizedDescription)
                    }
                    group.leave()
                }
            case .video(let video):
                storyCreator.addStoredVideo(asset: video)
                group.leave()
            }
        }
        group.notify(queue: .main) { [weak self] in
            guard let self = self else {
                return
            }
            self.assetParams = self.storyCreator.resultClipParams
            self.gallerySelected = true
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

//MARK: - EffectDurationDelegate

extension PreviewStoryViewModel: EffectDurationDelegate {
    func durationUpdated() {
        texts = storyCreator.texts
    }
}

extension PreviewStoryViewModel: VolumeAdjustmentViewControllerDelegate {
    func volumeChanged() {
        self.audioMix = storyCreator.resultClipParams.audioMix
    }
}
