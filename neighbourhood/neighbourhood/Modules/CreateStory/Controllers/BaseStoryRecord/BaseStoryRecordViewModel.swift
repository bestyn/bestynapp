//
//  BaseStoryRecordViewModel.swift
//  neighbourhood
//
//  Created by Artem Korzh on 01.03.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import Foundation
import AVFoundation

class BaseStoryRecordViewModel {

    lazy var videoRecordManager: VideoRecordManager = {
        let manager = VideoRecordManager()
        manager.delegate = self
        return manager
    }()

    var storyCreator: StoryCreator { .shared }
    var timer: Timer!
    var currentRecordDuration: Double = 0
    var maxDuration: Double = 0
    var maxLeftDuration: Double = 60.0
    var stoping = false

    var totalRecordedDuration: Double { recordedDurations.reduce(0, +) }

    @Observable var recordedDurations: [Double] = []
    @Observable var videoDevice: AVCaptureDevice!
    @Observable var isRecording: Bool = false
    @SingleEventObservable var error: String?


    public func toggleRecord() {
        if videoRecordManager.isRecording  {
            stopRecord()
            return
        }
        if totalRecordedDuration > maxDuration - 1 {
            return
        }
        guard videoRecordManager.startRecording() else {
            return
        }
        recordedDurations.append(0)
        currentRecordDuration = 0
        isRecording = true
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { (timer) in
            self.currentRecordDuration += 0.1
            self.recordedDurations[self.recordedDurations.count - 1] = self.currentRecordDuration
            if self.currentRecordDuration >= self.maxLeftDuration {
                self.stopRecord()
            }
        })
    }

    public func removeLastVideo() {
        storyCreator.removeLastVideo()
        updateRecordedDurations()
    }

    public func refreshAssets() {
        updateRecordedDurations()
    }

    private func updateRecordedDurations() {
        self.recordedDurations = storyCreator.recordedDurations
        self.maxLeftDuration = maxDuration - storyCreator.recordedLength
    }

    private func stopRecord() {
        if stoping {
            return
        }
        stoping = true
        func stop() {
            self.timer?.invalidate()
            self.videoRecordManager.stopRecording()
            self.isRecording = false
            self.currentRecordDuration = 0
            self.stoping = false
        }
        if recordedDurations.last! < 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1 - recordedDurations.last!) {
                stop()
            }
        } else {
            stop()
        }
    }
}

// MARK: - VideoRecordManagerDelegate

extension BaseStoryRecordViewModel: VideoRecordManagerDelegate {
    func videoRecordSetupStatusChanged(_ status: VideoRecordManager.SessionSetupResult) {

    }

    func videoRecordFailed(error: Error) {
        self.error = (error as NSError).localizedRecoverySuggestion ?? error.localizedDescription
        stopRecord()
    }

    func videoFileRecorded(fileURL: URL) {
        storyCreator.addRecordedVideo(fileURL: fileURL)
        updateRecordedDurations()
    }

    func cameraConfigurationChanged(device: AVCaptureDevice) {
        self.videoDevice = device
    }
}
