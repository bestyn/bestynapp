//
//  BaseStoryRecordViewController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 01.03.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import UIKit
import AVFoundation

class BaseStoryRecordViewController: UIViewController {

    @IBOutlet weak var cameraView: VideoPreviewView!
    @IBOutlet weak var flashButton: UIButton!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var recordsStackView: UIStackView!
    @IBOutlet weak var recordedActionsStackView: UIStackView!
    @IBOutlet weak var actionsStackView: UIStackView!
    @IBOutlet weak var backButton: UIButton!

    var viewModel = BaseStoryRecordViewModel()

    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        resumeCapture()
        viewModel.refreshAssets()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.videoRecordManager.pausePreview()
    }

    @IBAction func didTapBack(_ sender: Any) {
        StoryCreator.shared.reset()
        navigationController?.popViewController(animated: true)
    }

    @IBAction func didTapSwitchCamera(_ sender: Any) {
        toggleCamera()
    }

    @IBAction func didTapFlashToggle(_ sender: Any) {
        toggleFlash()
    }

    @IBAction func didTapRemoveVideo(_ sender: Any) {
        removeVideo()
    }

    @IBAction func didTapToggleRecord(_ sender: Any) {
        toggleRecord()
    }

    @IBAction func didTapConfirm(_ sender: Any) {
        if viewModel.storyCreator.resultClipParams.asset.duration.seconds < 1 {
            Toast.show(message: R.string.localizable.storyVideoTooShort())
            return
        }
        CreateStoryRouter(in: navigationController).openPreview()
    }

    private func setupCamera() {
        cameraView.session = viewModel.videoRecordManager.captureSession
        viewModel.videoRecordManager.setupCaptureSession()
    }

    private func toggleRecord() {
        viewModel.toggleRecord()
    }

    private func toggleCamera() {
        viewModel.videoRecordManager.switchCamera()
    }

    private func resumeCapture() {
        viewModel.videoRecordManager.startPreview()
    }

    private func toggleFlash() {
        viewModel.videoRecordManager.toggleFlash()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.updateFlashButtonState()
        }
    }

    private func removeVideo() {
        Alert(title: nil, message: Alert.Message.deleteLastClip)
            .configure(doneText: Alert.Action.delete)
            .configure(cancelText: Alert.Action.cancel)
            .show { (result) in
                if result == .done {
                    self.viewModel.removeLastVideo()
                }
            }
    }

    private func updateFlashButton(for device: AVCaptureDevice) {
        flashButton.isEnabled = device.hasTorch
        flashButton.alpha = device.hasTorch ? 1 : 0.3
    }

    private func updateFlashButtonState() {
        guard let device = viewModel.videoRecordManager.videoDevice else {
            return
        }
        flashButton.setImage(device.isTorchActive ?  R.image.stories_flash_off_icon() : R.image.stories_flash_on_icon(), for: .normal)
    }

    func updateDuration(_ durations: [Double]) {
        recordedActionsStackView.isHidden = durations.count == 0 || viewModel.isRecording
        backButton.setImage(durations.count > 0 ? R.image.stories_close_icon() : R.image.stories_back_icon(), for: .normal)
        recordsStackView.arrangedSubviews.forEach({$0.removeFromSuperview()})
        if durations.count == 0 {
            return
        }
        let maxWidth = recordsStackView.bounds.width - CGFloat(durations.count - 1) * recordsStackView.spacing
        durations.forEach { (duration) in
            let view = UIView()
            view.backgroundColor = R.color.accentRed()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.widthAnchor.constraint(equalToConstant: CGFloat(duration) * maxWidth / CGFloat(viewModel.maxDuration)).isActive = true
            recordsStackView.addArrangedSubview(view)
        }
        if viewModel.totalRecordedDuration < viewModel.maxDuration {
            recordsStackView.addArrangedSubview(UIView())
        }
    }

    func updateRecordingState(isRecording: Bool) {
        recordButton.setImage(isRecording ? R.image.stories_stop_icon() : R.image.stories_record_icon(), for: .normal)
        actionsStackView.isHidden = isRecording
        backButton.isHidden = isRecording
    }

    func setupViewModel() {
        viewModel.$videoDevice.bind { [weak self] (device) in
            guard let device = device else {
                return
            }
            self?.updateFlashButton(for: device)
        }

        viewModel.$recordedDurations.bind { [weak self] (durations) in
            self?.updateDuration(durations)

        }
        viewModel.$isRecording.bind { [weak self] (isRecording) in
            self?.updateRecordingState(isRecording: isRecording)
        }
    }
}
