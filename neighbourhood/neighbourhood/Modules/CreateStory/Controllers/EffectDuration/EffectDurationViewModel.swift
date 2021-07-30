//
//  EffectDurationViewModel.swift
//  neighbourhood
//
//  Created by Artem Korzh on 19.01.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import UIKit

protocol EffectDurationDelegate: class {
    func durationUpdated()
}

class EffectDurationViewModel {


    public var storyCreator: StoryCreator { .shared }
    public lazy var backgroundLayer: CAGradientLayer = storyCreator.textBackgroundLayer.copy() ?? CAGradientLayer()
    public var isTextMode: Bool { storyCreator.mode == .text }

    public weak var delegate: EffectDurationDelegate?

    @Observable private(set) var assetParams: VideoAssetParams
    @Observable private(set) var texts: [StoryCreator.TextEntity]
    @Observable private(set) var currentEntity: StoryCreator.TextEntity

    init(entity: StoryCreator.TextEntity) {
        assetParams = .init(
            asset: StoryCreator.shared.sourceClipContent.composition,
            videoComposition: StoryCreator.shared.sourceClipContent.videoComposition,
            layerComposition: StoryCreator.shared.sourceClipContent.layerComposition,
            audioMix: StoryCreator.shared.sourceClipContent.audioMix)
        texts = StoryCreator.shared.texts
        currentEntity = entity
    }

    public func updateDuration(range: ClosedRange<Double>) {
        currentEntity.range = range
        texts = texts.map({ (originalEntity) -> StoryCreator.TextEntity in
            if originalEntity == currentEntity {
                return currentEntity
            }
            return originalEntity
        })
    }

    public func confirmEdit() {
        storyCreator.updateTextEntity(for: currentEntity)
        delegate?.durationUpdated()
    }
}
