//
//  VideoRecordManager.swift
//  neighbourhood
//
//  Created by Artem Korzh on 30.11.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import AVFoundation
import UIKit

protocol VideoRecordManagerDelegate: class {
    func videoRecordSetupStatusChanged(_ status: VideoRecordManager.SessionSetupResult)
    func videoFileRecorded(fileURL: URL)
    func videoRecordFailed(error: Error)
    func cameraConfigurationChanged(device: AVCaptureDevice)
}

class VideoRecordManager: NSObject {

    enum SessionSetupResult {
        case idle
        case success
        case notAuthorized
        case configurationFailed
    }

    let captureSession = AVCaptureSession()
    weak var delegate: VideoRecordManagerDelegate?
    var isRecording: Bool { movieFileOutput.isRecording }
    private var isMicEnabled: Bool = true

    private let captureSessionQueue = DispatchQueue(label: "captureSessionQueue")
    private var setupResult: SessionSetupResult = .idle {
        didSet { delegate?.videoRecordSetupStatusChanged(setupResult) }
    }
    private(set) var videoDevice: AVCaptureDevice!

    private let photoOutput = AVCapturePhotoOutput()
    private var videoDeviceInput: AVCaptureDeviceInput!
    private var audioDeviceInput: AVCaptureDeviceInput?
    private var movieFileOutput = AVCaptureMovieFileOutput()
    private var backgroundRecordingID: UIBackgroundTaskIdentifier?

    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera],
        mediaType: .video, position: .unspecified)

    deinit {
        captureSession.stopRunning()
    }

    func setupCaptureSession() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupResult = .success
            break
        case .notDetermined:
            captureSessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video) { (granted) in
                self.setupResult = granted ? .success : .notAuthorized
                self.captureSessionQueue.resume()
            }
        default:
            setupResult = .notAuthorized
            Alert(title: Alert.Title.storyPermissions, message: Alert.Message.storyPermissions(appName: Configuration.appName))
                .configure(doneText: Alert.Action.openSettings)
                .configure(cancelText: Alert.Action.cancel)
                .show { (result) in
                    if result == .done {
                        if let url = URL(string: UIApplication.openSettingsURLString),
                           UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
        }

        captureSessionQueue.async {
            self.setupSession()
        }
        DispatchQueue.main.async {
            #warning("loading")
        }
    }

    func toggleFlash() {
        guard setupResult == .success else {
            return
        }
        do {
            try videoDevice.lockForConfiguration()
            videoDevice.torchMode = videoDevice.torchMode == .on ? .off : .on
            videoDevice.unlockForConfiguration()
        } catch {
            print(error)
        }
    }

    func startPreview() {
        captureSessionQueue.async {
            switch self.setupResult {
            case .success:
//                self.addObservers()
                self.captureSession.startRunning()
//                self.isSessionRunning = self.session.isRunning
            default:
                break
            }
        }
    }

    func pausePreview() {
        if self.captureSession.isRunning {
            self.captureSession.stopRunning()
        }
    }

    private func setupSession() {
        defer {
            startPreview()
        }
        if setupResult != .success {
            return
        }
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high
        do {
            var defaultVideoDevice: AVCaptureDevice?
            if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                defaultVideoDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                defaultVideoDevice = frontCameraDevice
            }
            guard let videoDevice = defaultVideoDevice else {
                print("Default video device is unavailable.")
                setupResult = .configurationFailed
                captureSession.commitConfiguration()
                return
            }
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)

            if captureSession.canAddInput(videoDeviceInput) {
                captureSession.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                self.videoDevice = videoDevice

                DispatchQueue.main.async {
                    self.delegate?.cameraConfigurationChanged(device: self.videoDevice)
                }
            } else {
                print("Couldn't add video device input to the captureSession.")
                setupResult = .configurationFailed
                captureSession.commitConfiguration()
                return
            }
        } catch {
            print("Couldn't create video device input: \(error)")
            setupResult = .configurationFailed
            captureSession.commitConfiguration()
            return
        }

        // Add an audio input device.
        do {
            let audioDevice = AVCaptureDevice.default(for: .audio)
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice!)
            self.audioDeviceInput = audioDeviceInput

            if captureSession.canAddInput(audioDeviceInput) {
                captureSession.addInput(audioDeviceInput)
            } else {
                print("Could not add audio device input to the session")
            }
        } catch {
            print("Could not create audio device input: \(error)")
        }

        // Add the photo output.
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)

            photoOutput.isHighResolutionCaptureEnabled = true
            photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
            photoOutput.isDepthDataDeliveryEnabled = photoOutput.isDepthDataDeliverySupported

        } else {
            print("Could not add photo output to the session")
            setupResult = .configurationFailed
            captureSession.commitConfiguration()
            return
        }

        captureSession.addOutput(movieFileOutput)

        captureSession.commitConfiguration()
    }

    public func setMicEnabled(_ enabled: Bool) {
        guard !isRecording else {
            return
        }
        guard let audioDeviceInput = audioDeviceInput else {
            return
        }
        if enabled {
            if captureSession.inputs.contains(audioDeviceInput) {
                return
            }
            captureSession.addInput(audioDeviceInput)
        } else {
            captureSession.removeInput(audioDeviceInput)
        }
    }

    func startRecording() -> Bool {
        if setupResult != .success {
            setupCaptureSession()
            return false
        }
        if self.movieFileOutput.isRecording {
            return false
        }
        captureSessionQueue.async {
                if UIDevice.current.isMultitaskingSupported {
                    self.backgroundRecordingID = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
                }

                // Update the orientation on the movie file output video connection before recording.
                let movieFileOutputConnection = self.movieFileOutput.connection(with: .video)
                movieFileOutputConnection?.videoOrientation = .portrait

                let availableVideoCodecTypes = self.movieFileOutput.availableVideoCodecTypes

                if availableVideoCodecTypes.contains(.hevc) {
                    self.movieFileOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: movieFileOutputConnection!)
                }

                // Start recording video to a temporary file.
                let outputFileName = NSUUID().uuidString
                let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
                self.movieFileOutput.startRecording(to: URL(fileURLWithPath: outputFilePath), recordingDelegate: self)
        }
        return true
    }

    public func stopRecording() {
        guard movieFileOutput.isRecording else {
            return
        }
        self.movieFileOutput.stopRecording()
    }

    public func switchCamera() {
        guard setupResult == .success else {
            return
        }
        captureSessionQueue.async {
            let currentVideoDevice = self.videoDeviceInput.device
            let currentPosition = currentVideoDevice.position

            let preferredPosition: AVCaptureDevice.Position
            let preferredDeviceType: AVCaptureDevice.DeviceType

            switch currentPosition {
            case .unspecified, .front:
                preferredPosition = .back
                preferredDeviceType = .builtInDualCamera

            case .back:
                preferredPosition = .front
                preferredDeviceType = .builtInWideAngleCamera

            @unknown default:
                print("Unknown capture position. Defaulting to back, dual-camera.")
                preferredPosition = .back
                preferredDeviceType = .builtInDualCamera
            }
            let devices = self.videoDeviceDiscoverySession.devices
            var newVideoDevice: AVCaptureDevice? = nil

            // First, seek a device with both the preferred position and device type. Otherwise, seek a device with only the preferred position.
            if let device = devices.first(where: { $0.position == preferredPosition && $0.deviceType == preferredDeviceType }) {
                newVideoDevice = device
            } else if let device = devices.first(where: { $0.position == preferredPosition }) {
                newVideoDevice = device
            }

            if let videoDevice = newVideoDevice {
                do {
                    let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)

                    self.captureSession.beginConfiguration()
                    self.captureSession.removeInput(self.videoDeviceInput)

                    if self.captureSession.canAddInput(videoDeviceInput) {
                        self.captureSession.addInput(videoDeviceInput)
                        self.videoDevice = videoDevice
                        self.videoDeviceInput = videoDeviceInput
                    } else {
                        self.captureSession.addInput(self.videoDeviceInput)
                    }
                    if let connection = self.movieFileOutput.connection(with: .video) {
                        if connection.isVideoStabilizationSupported {
                            connection.preferredVideoStabilizationMode = .auto
                        }
                    }
                    self.photoOutput.isLivePhotoCaptureEnabled = self.photoOutput.isLivePhotoCaptureSupported
                    self.photoOutput.isDepthDataDeliveryEnabled = self.photoOutput.isDepthDataDeliverySupported

                    self.captureSession.commitConfiguration()
                    DispatchQueue.main.async {
                        self.delegate?.cameraConfigurationChanged(device: self.videoDevice)
                    }
                } catch {
                    print("Error occurred while creating video device input: \(error)")
                }
            }

            DispatchQueue.main.async {
                #warning("enable controls")
            }
        }
    }
    
}

extension VideoRecordManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            delegate?.videoRecordFailed(error: error)
            return
        }
        delegate?.videoFileRecorded(fileURL: outputFileURL)
        if let backgroundRecordingID = backgroundRecordingID {
            UIApplication.shared.endBackgroundTask(backgroundRecordingID)
        }
    }
}
