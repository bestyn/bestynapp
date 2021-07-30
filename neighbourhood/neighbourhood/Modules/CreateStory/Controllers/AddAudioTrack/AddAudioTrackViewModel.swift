//
//  AddAudioTrackViewModel.swift
//  neighbourhood
//
//  Created by Artem Korzh on 11.02.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import Foundation

class AddAudioTrackViewModel {

    public let audioTrackURL: URL

    private(set) var description: String = ""
    @Observable private(set) var startSecond: Double = 0
    @SingleEventObservable var saveResult: Result<Void, Error>?
    @Observable var isSending: Bool = false
    @Observable var descriptionError: String?
    @SingleEventObservable var startSecondError: String?

    private lazy var audioManager: RestAudioTracksManager = RestService.shared.createOperationsManager(from: self)

    init(audioTrackURL: URL) {
        self.audioTrackURL = audioTrackURL
    }


}

// MARK: - Public methods

extension AddAudioTrackViewModel {
    public func changeStartSecond(_ second: Double) {
        self.startSecond = second
    }

    public func setDescription(_ description: String) {
        self.description = description
    }

    public func save() {
        guard isValidData() else {
            return
        }
        let data = AudioTrackData(file: audioTrackURL, trimStart: startSecond, description: description)
        restSaveAudioTrack(data: data)
    }
}

// MARK: - Private methods

extension AddAudioTrackViewModel {
    private func isValidData() -> Bool {
        var isValid = true
        descriptionError = nil
        let validation = ValidationManager()
        if let descriptionError = validation.validate(value: description, rules: [.required, .tooLong(max: 50)])
            .errorMessage(field: "Description") {
            self.descriptionError = descriptionError
            isValid = false
        }
        return isValid
    }
}

// MARK: - REST requests

extension AddAudioTrackViewModel {

    private func restSaveAudioTrack(data: AudioTrackData) {
        audioManager.saveTrack(data: data)
            .onStateChanged { [weak self] (state) in
                self?.isSending = state == .started
            }.onError { [weak self] (error) in
                self?.saveResult = .failure(error)
            }.onComplete { [weak self] (_) in
                self?.saveResult = .success(())
            }.run()
    }
}
