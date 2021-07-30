//
//  VoiceMessageManager.swift
//  neighbourhood
//
//  Created by Dioksa on 29.07.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import AVFoundation
import SoundWave

struct SoundRecord {
    var audioFilePathLocal: URL?
    var meteringLevels: [Float]?
}

final class VoiceMessageManager: NSObject {

    static let shared = VoiceMessageManager()

    var audioVisualizationTimeInterval: TimeInterval = 0.05 // Time interval between each metering bar representation

    private(set) var audioURL: URL?
    private var isFetchingAudio = false
    private var timer: Timer?
    private var durations: [URL: CMTime] = [:]
    var currentAudioRecord: SoundRecord?
    var isPlaying = false
    var leftDuration: TimeInterval { AudioPlayerManager.shared.leftDuration }
    private(set) var currentSpeakingMessage: PrivateChatMessageModel?
    private lazy var synthesizer: AVSpeechSynthesizer = {
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.delegate = self
        return synthesizer
    }()

    var audioMeteringLevelUpdate: ((Float) -> ())?
    var audioDidFinish: (() -> ())?

    override init() {
        super.init()
        // notifications update metering levels
        NotificationCenter.default.addObserver(self, selector: #selector(VoiceMessageManager.didReceiveMeteringLevelUpdate),
                                               name: .audioPlayerManagerMeteringLevelDidUpdateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(VoiceMessageManager.didReceiveMeteringLevelUpdate),
                                               name: .audioRecorderManagerMeteringLevelDidUpdateNotification, object: nil)

        // notifications audio finished
        NotificationCenter.default.addObserver(self, selector: #selector(VoiceMessageManager.didFinishRecordOrPlayAudio),
                                               name: .audioPlayerManagerMeteringLevelDidFinishNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(VoiceMessageManager.didFinishRecordOrPlayAudio),
                                               name: .audioRecorderManagerMeteringLevelDidFinishNotification, object: nil)
    }

    // MARK: - Recording
    func askAudioRecordingPermission(completion: ((Bool) -> Void)? = nil) {
        return AudioRecorderManager.shared.askPermission(completion: completion)
    }

    func startRecording(completion: @escaping (SoundRecord?, Error?) -> Void) {
        AudioRecorderManager.shared.startRecording(with: self.audioVisualizationTimeInterval, completion: { [weak self] url, error in
            guard let url = url else {
                completion(nil, error!)
                return
            }

            self?.currentAudioRecord = SoundRecord(audioFilePathLocal: url, meteringLevels: [])
            ArchiveService.shared.url = url
            completion(self?.currentAudioRecord, nil)
        })
    }

    func stopRecording() throws {
        try AudioRecorderManager.shared.stopRecording()
    }

    func resetRecording() throws {
        try AudioRecorderManager.shared.reset()
        self.isPlaying = false
        self.currentAudioRecord = nil
    }

    // MARK: - Playing
    func startPlaying(url: URL) throws -> TimeInterval {
        let currentAudioRecord = SoundRecord(audioFilePathLocal: url, meteringLevels: [0.05])
        guard let audioFilePath = currentAudioRecord.audioFilePathLocal else {
            fatalError("tried to unwrap audio file path that is nil")
        }

        self.isPlaying = true
        return try AudioPlayerManager.shared.play(at: audioFilePath, with: self.audioVisualizationTimeInterval)
    }

    private func pausePlaying() throws {
        try AudioPlayerManager.shared.pause()
        NotificationCenter.default.post(name: .pausePlayingVoiceMessage, object: self.audioURL)
        isPlaying = false
    }
    
    func stopPlaying() {
        try? AudioPlayerManager.shared.stop()
        isPlaying = false
        NotificationCenter.default.post(name: .stopPlayingVoiceMessage, object: self.audioURL)
        self.audioURL = nil
    }

    // MARK: - Notifications Handling
    @objc private func didReceiveMeteringLevelUpdate(_ notification: Notification) {
        let percentage = notification.userInfo![audioPercentageUserInfoKey] as! Float
        self.audioMeteringLevelUpdate?(percentage)
    }

    @objc private func didFinishRecordOrPlayAudio(_ notification: Notification) {
        if isPlaying {
            stopPlaying()
        } else {
            self.audioDidFinish?()
        }
    }

    func togglePlay(audioURL: URL) {
        stopSpeaking()
        if let oldAudioURL = self.audioURL {
            if oldAudioURL == audioURL {
                if isPlaying {
                    try? pausePlaying()
                } else {
                    if let duration = try? AudioPlayerManager.shared.resume() {
                        NotificationCenter.default.post(name: .startPlayingVoiceMessage, object: (oldAudioURL, duration))
                        isPlaying = true
                    }
                }
                return
            }
            stopPlaying()
            NotificationCenter.default.post(name: .stopPlayingVoiceMessage, object: oldAudioURL)
        }

        self.audioURL = audioURL
        checkLocalAudio { [weak self] (url) in
            if let url = url {
                self?.playLocalAudio(url: url)
            }
        }
    }

    private func checkLocalAudio(completion: @escaping (URL?) -> Void) {
        guard let audioUrl = audioURL, let localURL = URL.documentsPath(forFileName: audioUrl.lastPathComponent) else {
            return
        }

        if FileManager.default.fileExists(atPath: localURL.path) {
            completion(localURL)
            return
        }

        isFetchingAudio = true

        URLSession(configuration: .default).downloadTask(with: URLRequest(url: audioUrl)) { [weak self] (tempURL, _, error) in
            self?.isFetchingAudio = false
            if let error = error {
                print(error.localizedDescription)
                completion(nil)
                return
            }
            guard let tempURL = tempURL else {
                print("Failed to fetch audio message")
                completion(nil)
                return
            }
            do {
                try FileManager.default.copyItem(at: tempURL, to: localURL)
                completion(localURL)
            } catch {
                print(error.localizedDescription)
                completion(nil)
            }
        }.resume()

    }
    
    func getAudioDuration(url: URL?, completion: @escaping (CMTime?) -> Void) {
        guard let url = url else {
            completion(nil)
            return
        }
        if let time = durations[url] {
            completion(time)
            return
        }
        DispatchQueue.global().async {
            let audioAsset = AVURLAsset.init(url: url, options: nil)
            let duration = audioAsset.duration
            DispatchQueue.main.async {
                self.durations[url] = duration
                completion(duration)
            }
        }
    }

    func toggleSpeakText(message: PrivateChatMessageModel) {
        stopPlaying()
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        if currentSpeakingMessage?.id == message.id {
            if synthesizer.isPaused {
                continueSpeaking()
            } else {
                pauseSpeaking()
            }
        } else {
            startSpeaking(message: message)
        }
    }

    private func startSpeaking(message: PrivateChatMessageModel) {
        stopSpeaking()
        currentSpeakingMessage = message
        let utterance = AVSpeechUtterance(string: message.text)
        utterance.voice = AVSpeechSynthesisVoice(language: GlobalConstants.Languages.speechLanguage)
        utterance.rate = 0.5
        synthesizer.speak(utterance)
        NotificationCenter.default.post(name: .startSpeakingTextMessage, object: message.id)
    }

    private func continueSpeaking() {
        synthesizer.continueSpeaking()
        NotificationCenter.default.post(name: .startSpeakingTextMessage, object: currentSpeakingMessage?.id)
    }

    private func pauseSpeaking() {
        synthesizer.pauseSpeaking(at: .immediate)
        NotificationCenter.default.post(name: .stopSpeakingTextMessage, object: currentSpeakingMessage?.id)
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        NotificationCenter.default.post(name: .stopSpeakingTextMessage, object: currentSpeakingMessage?.id)
        currentSpeakingMessage = nil
    }

    private func playLocalAudio(url: URL) {
        if let duration = try? startPlaying(url: url) {
            NotificationCenter.default.post(name: .startPlayingVoiceMessage, object: (audioURL, duration))
        }
    }
}

extension VoiceMessageManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        stopSpeaking()
    }
}
