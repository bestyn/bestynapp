//
//  CreateDuetViewModel.swift
//  neighbourhood
//
//  Created by Artem Korzh on 17.02.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import Foundation
import AVFoundation

class CreateDuetViewModel: BaseStoryRecordViewModel {

    @Observable private(set) var isMicEnabled: Bool = true

    var originAsset: AVAsset? { storyCreator.duetOriginAsset }

    init(originStory: PostModel) {
        super.init()
        storyCreator.setDuetOrigin(story: originStory)
        maxDuration = originAsset?.duration.seconds ?? 0
        maxLeftDuration = maxDuration
    }
}

// MARK: - Public methods

extension CreateDuetViewModel {

    public func toggleMic() {
        isMicEnabled.toggle()
        videoRecordManager.setMicEnabled(isMicEnabled)
    }
}

// MARK: - Private methods

extension CreateDuetViewModel {
    private func stopRecord() {
        if stoping {
            return
        }
        stoping = true
        func stop() {
            self.timer?.invalidate()
            self.videoRecordManager.stopRecording()
            self.currentRecordDuration = 0
            self.stoping = false
        }
        if currentRecordDuration < 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1 - self.currentRecordDuration) {
                stop()
            }
        } else {
            stop()
        }
    }

    private func updateRecordedDurations() {
        recordedDurations = storyCreator.recordedDurations
        maxLeftDuration = maxDuration - totalRecordedDuration
    }
}
