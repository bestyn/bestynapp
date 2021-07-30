//
//  AudioRecorderManager.swift
//  neighbourhood
//
//  Created by Dioksa on 29.07.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import AVFoundation

let audioPercentageUserInfoKey = "percentage"

final class AudioRecorderManager: NSObject {
    let audioFileNamePrefix = "audio_mp3"
    let encoderBitRate: Int = 320000
    let numberOfChannels: Int = 2
    let sampleRate: Double = 44100.0
    private var recordingSession: AVAudioSession!

    static let shared = AudioRecorderManager()

    var isPermissionGranted = false
    var isRunning: Bool {
        guard let recorder = self.recorder, recorder.isRecording else {
            return false
        }
        return true
    }

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption(notification:)), name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    var currentRecordPath: URL?

    private var recorder: AVAudioRecorder?
    private var audioMeteringLevelTimer: Timer?
    
    func askPermission(completion: ((Bool) -> Void)? = nil) {
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .duckOthers])
            try recordingSession.overrideOutputAudioPort(.none)

            try recordingSession.setActive(true)
            
            recordingSession.requestRecordPermission { [unowned self] granted in
                self.isPermissionGranted = granted
                DispatchQueue.main.async {
                    completion?(granted)
                }
                print("Audio Recorder grant permission")
            }
        } catch {
            print("Audio Recorder did not grant permission")
        }
    }


    func startRecording(with audioVisualizationTimeInterval: TimeInterval = 0.05, completion: @escaping (URL?, Error?) -> Void) {
        func startRecordingReturn() {
            do {
                completion(try internalStartRecording(with: audioVisualizationTimeInterval), nil)
            } catch {
                completion(nil, error)
            }
        }
        
        if !self.isPermissionGranted {
            self.askPermission { granted in
                startRecordingReturn()
            }
        } else {
            startRecordingReturn()
        }
    }
    
    fileprivate func internalStartRecording(with audioVisualizationTimeInterval: TimeInterval) throws -> URL {
        if self.isRunning {
            throw AudioErrorType.alreadyPlaying
        }
        
        let recordSettings = [
            AVFormatIDKey: NSNumber(value:kAudioFormatLinearPCM),
            AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue,
            AVEncoderBitRateKey : self.encoderBitRate,
            AVNumberOfChannelsKey: self.numberOfChannels,
            AVSampleRateKey : self.sampleRate
        ] as [String : Any]
        
        guard let path = URL.documentsPath(forFileName: self.audioFileNamePrefix + NSUUID().uuidString + ".wav") else {
            print("Incorrect path for new audio file")
            throw AudioErrorType.audioFileWrongPath
        }

        try AVAudioSession.sharedInstance()
            .setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth, .duckOthers, .defaultToSpeaker])
        try AVAudioSession.sharedInstance().setActive(true)
        
        self.recorder = try AVAudioRecorder(url: path, settings: recordSettings)
        self.recorder!.delegate = self
        self.recorder!.isMeteringEnabled = true
        
        if !self.recorder!.prepareToRecord() {
            print("Audio Recorder prepare failed")
            throw AudioErrorType.recordFailed
        }
        
        if !self.recorder!.record() {
            print("Audio Recorder start failed")
            throw AudioErrorType.recordFailed
        }
        
        self.audioMeteringLevelTimer = Timer.scheduledTimer(timeInterval: audioVisualizationTimeInterval, target: self,
            selector: #selector(AudioRecorderManager.timerDidUpdateMeter), userInfo: nil, repeats: true)
        
        print("Audio Recorder did start - creating file at index: \(path.absoluteString)")
        
        self.currentRecordPath = path
        return path
    }

    func stopRecording() throws {
        self.audioMeteringLevelTimer?.invalidate()
        self.audioMeteringLevelTimer = nil
        
        if !self.isRunning {
            print("Audio Recorder did fail to stop")
            throw AudioErrorType.notCurrentlyPlaying
        }
        
        self.recorder!.stop()
        try AVAudioSession.sharedInstance()
            .setCategory(.playback)
        print("Audio Recorder did stop successfully")
    }

    func reset() throws {
        if self.isRunning {
            print("Audio Recorder tried to remove recording before stopping it")
            throw AudioErrorType.alreadyRecording
        }
        
        self.recorder?.deleteRecording()
        self.recorder = nil
        self.currentRecordPath = nil
        
        print("Audio Recorder did remove current record successfully")
    }

    @objc func timerDidUpdateMeter() {
        if self.isRunning {
            self.recorder!.updateMeters()
            let averagePower = recorder!.averagePower(forChannel: 0)
            let percentage: Float = pow(10, (0.05 * averagePower))
            NotificationCenter.default.post(name: .audioRecorderManagerMeteringLevelDidUpdateNotification, object: self, userInfo: [audioPercentageUserInfoKey: percentage])
        }
    }

    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        switch type {
        case .began:
            try? stopRecording()
        case .ended:
            break
        @unknown default:
            break
        }

    }
}

extension AudioRecorderManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        NotificationCenter.default.post(name: .audioRecorderManagerMeteringLevelDidFinishNotification, object: self)
        print("Audio Recorder finished successfully")
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        NotificationCenter.default.post(name: .audioRecorderManagerMeteringLevelDidFailNotification, object: self)
        print("Audio Recorder error")
    }
}

extension Notification.Name {
    static let audioRecorderManagerMeteringLevelDidUpdateNotification = Notification.Name("AudioRecorderManagerMeteringLevelDidUpdateNotification")
    static let audioRecorderManagerMeteringLevelDidFinishNotification = Notification.Name("AudioRecorderManagerMeteringLevelDidFinishNotification")
    static let audioRecorderManagerMeteringLevelDidFailNotification = Notification.Name("AudioRecorderManagerMeteringLevelDidFailNotification")
}


enum AudioErrorType: Error {
    case alreadyRecording
    case alreadyPlaying
    case notCurrentlyPlaying
    case audioFileWrongPath
    case recordFailed
    case playFailed
    case recordPermissionNotGranted
    case internalError
}

extension AudioErrorType: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .alreadyRecording:
            return "The application is currently recording sounds"
        case .alreadyPlaying:
            return "The application is already playing a sound"
        case .notCurrentlyPlaying:
            return "The application is not currently playing"
        case .audioFileWrongPath:
            return "Invalid path for audio file"
        case .recordFailed:
            return "Unable to record sound at the moment, please try again"
        case .playFailed:
            return "Unable to play sound at the moment, please try again"
        case .recordPermissionNotGranted:
            return "Unable to record sound because the permission has not been granted. This can be changed in your settings."
        case .internalError:
            return "An error occured while trying to process audio command, please try again"
        }
    }
}
