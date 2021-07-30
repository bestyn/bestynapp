//
//  ClipAdjustmentViewModel.swift
//  neighbourhood
//
//  Created by Artem Korzh on 23.12.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

class ClipAdjustmentViewModel {
    enum EditMode {
        case wholeClip
        case singleClip
    }

    private var storyCreator: StoryCreator { .shared }
    private var currentCLip: StoryCreator.VideoEntity!

    @Observable private(set) var currentAssetParams: VideoAssetParams
    @Observable private(set) var mode: EditMode = .wholeClip
    @SingleEventObservable private(set) var saveResult: Result<Void, Error>?
    @Observable private(set) var clips: [StoryCreator.VideoEntity]
    @Observable private(set) var isSelectingMode: Bool = false
    @SingleEventObservable private(set) var selectedFrame: Double = 0
    private lazy var totalRange: ClosedRange<Double> = storyCreator.editingClipContent.finalRange
    private(set) var clipRange: ClosedRange<Double>!

    var minSeconds: Double { mode == .singleClip ? clipRange.lowerBound : totalRange.lowerBound }
    var maxSeconds: Double { mode == .singleClip ? clipRange.upperBound : totalRange.upperBound }
    var canAddMediaFromGallery: Bool { storyCreator.mode == .gallery }

    init() {
        StoryCreator.shared.clearTexts()
        StoryCreator.shared.startEditing()
        currentAssetParams = StoryCreator.shared.editingClipContent.assetParams
        clips = StoryCreator.shared.editingClipContent.videoEntities
    }

    public func selectClip(_ clip: StoryCreator.VideoEntity) {
        clipRange = clip.range
        currentCLip = clip
        mode = .singleClip
        currentAssetParams = VideoAssetParams(asset: clip.asset, videoComposition: clip.videoComposition, layerComposition: nil, audioMix: nil)
    }

    public func confirmClipEdit() {
        storyCreator.setEditingClipRange(for: currentCLip, range: clipRange)
        mode = .wholeClip
        clips = storyCreator.editingClipContent.videoEntities
        totalRange = storyCreator.editingClipContent.finalRange
        currentAssetParams = storyCreator.editingClipContent.assetParams
        currentCLip = nil
        clipRange = nil
    }

    public func cancelClipEdit() {
        mode = .wholeClip
        currentAssetParams = storyCreator.editingClipContent.assetParams
        currentCLip = nil
        clipRange = nil
    }

    public func saveEdit() {
        storyCreator.setEditingTotalRange(totalRange)
        storyCreator.saveEdit()
        saveResult = .success(())
    }

    public func removeSelectedClip() {
        storyCreator.removeClip(currentCLip)
        mode = .wholeClip
        clips = storyCreator.editingClipContent.videoEntities
        if clips.count == 0 {
            storyCreator.setMode(.recorded)
            return
        }
        totalRange = storyCreator.editingClipContent.finalRange
        currentAssetParams = storyCreator.editingClipContent.assetParams
        currentCLip = nil
        clipRange = nil
    }

    public func moveClip(from oldPosition: Int, to newPosition: Int) {
        storyCreator.moveClip(from: oldPosition, to: newPosition)
        currentAssetParams = storyCreator.editingClipContent.assetParams
        clips = storyCreator.editingClipContent.videoEntities
    }
}


// MARK: - VideoSliderDelegate

extension ClipAdjustmentViewModel: VideoSliderDelegate {
    func rangeChanged(_ range: ClosedRange<Double>) {
        if mode == .singleClip {
            clipRange = range
        } else {
            totalRange = range
        }
    }

    func frameChanged(second: Double) {
        selectedFrame = second
    }

    func dragEnded() {
        isSelectingMode = false
    }

    func dragStarted() {
        isSelectingMode = true
    }

}

// MARK: - GallerySelectorDelegate

extension ClipAdjustmentViewModel: GallerySelectorDelegate {
    func mediaSelected(entities: [GallerySelectionEntity]) {
        let group = DispatchGroup()
        entities.forEach { (entity) in
            group.enter()
            switch entity {
            case .image(let image):
                storyCreator.addStoredImage(image: image) { error in
                    if let error = error {
                        print(error)
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
            self.currentAssetParams = self.storyCreator.editingClipContent.assetParams
            self.clips = self.storyCreator.editingClipContent.videoEntities
            self.totalRange = self.storyCreator.editingClipContent.finalRange
        }
    }

    func canSelectMore(mediaType: GallerySelectorMediaType, imagesSelected: Int, videosSelected: Int) -> Bool {
        if imagesSelected + videosSelected < 30 - storyCreator.editingClipContent.videoEntities.count {
            return true
        }
        Toast.show(message: R.string.localizable.maxMediaSelected())
        return false
    }
}
