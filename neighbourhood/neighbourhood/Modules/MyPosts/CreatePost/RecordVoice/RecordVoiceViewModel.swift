//
//  RecordVoiceViewModel.swift
//  neighbourhood
//
//  Created by Artem Korzh on 29.03.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import Foundation
import AVFoundation

protocol RecordVoiceDelegate: class {
    func audioRecorded(url: URL)
}


class RecordVoiceViewModel {

    enum State {
        case idle
        case recording
        case recorded
        case playing
    }

    public static var shared = RecordVoiceViewModel()

    @Observable private(set) var recordState: State = .idle
    @Observable private(set) var recordDuration: Double = 0
    @Observable private(set) var error: Error?

    private lazy var recorder = AudioRecorderManager()
    private var timer: Timer!
    private(set) var recordedURL: URL?
    private let audioService = AudioPlayerService()

    weak var delegate: RecordVoiceDelegate?

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(recordStopped), name: .audioRecorderManagerMeteringLevelDidFinishNotification, object: nil)
    }

}


extension RecordVoiceViewModel {
    public func toggleRecord() {
        if recorder.isRunning {
            try? recorder.stopRecording()
            return
        }
        recorder.askPermission { [weak self] (isGranted) in
            guard isGranted else {
                //
                return
            }
            self?.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] (timer) in

                self?.handleTimerTick(interval: timer.timeInterval)
            })
            self?.recordState = .recording
            self?.recorder.startRecording { [weak self] (url, error) in
                if let error = error {
                    self?.error = error
                    return
                }
                self?.recordedURL = self?.recorder.currentRecordPath
            }
        }

    }

    public func togglePlay() {
        guard let url = recordedURL else {
            return
        }
        if audioService.isPlaying {
            audioService.pause()
            recordState = .recorded
            return
        }
        audioService.play(url: url)
        recordState = .playing
    }

    public func stop() {
        if audioService.isPlaying {
            audioService.stop()
        }
    }

    public func removeRecorded() {
        stop()
        try? recorder.reset()
        recordDuration = 0
        recordState = .idle
    }

    public func confirm() {
        guard let url = recordedURL else {
            return
        }
        delegate?.audioRecorded(url: url)
        self.reset()
    }

    public func seekPlayer(second: Double) {
        guard let url = recordedURL else {
            return
        }
        audioService.seek(url: url, to: second)
    }

    public func reset() {
        stop()
        try? recorder.stopRecording()
        try? recorder.reset()
        recordState = .idle
        recordDuration = 0
    }
}


extension RecordVoiceViewModel {

    @objc private func recordStopped() {
        timer.invalidate()
        if recordState == .recording {
            recordState = .recorded
        }
    }

    private func handleTimerTick(interval: Double) {
        recordDuration += timer.timeInterval
        if recordDuration >= 18000, recorder.isRunning {
            toggleRecord()
        }
    }

    func checkVoiceRecording() -> Bool {
        if recordState == .recording || recordState == .recorded {
            Toast.show(message: R.string.localizable.audioRecordingInProgress())
            return false
        }
        return true
    }
}
