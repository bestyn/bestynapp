//
//  CreateDuetViewController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 17.02.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import UIKit
import AVFoundation

class CreateDuetViewController: BaseStoryRecordViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var originalStoryView: UIView!
    @IBOutlet weak var switchCamButton: UIButton!
    @IBOutlet weak var micButton: UIButton!

    private let player = AVPlayer()
    private lazy var playerLayer = AVPlayerLayer(player: player)
    var createDuetViewModel: CreateDuetViewModel { viewModel as! CreateDuetViewModel }

    // MARK: - Lifecycle

    init(originStory: PostModel) {
        super.init()
        viewModel = CreateDuetViewModel(originStory: originStory)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPlayer()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updatePlayerAsset()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.videoRecordManager.pausePreview()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer.frame = originalStoryView.bounds
    }

    // MARK: - Overrides

    override func setupViewModel() {
        super.setupViewModel()
        createDuetViewModel.$isMicEnabled.bind { [weak self] (isMicEnabled) in
            self?.updateMicButtonState(isMicEnabled: isMicEnabled)
            if isMicEnabled {
                Toast.show(message: R.string.localizable.duetRecordingMicNotification())
            }
        }
    }

    override func updateDuration(_ durations: [Double]) {
        super.updateDuration(durations)
        self.micButton.isEnabled = durations.count == 0
        if !viewModel.isRecording {
            player.seek(to: CMTime(seconds: viewModel.totalRecordedDuration, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
        }
    }

    override func updateRecordingState(isRecording: Bool) {
        super.updateRecordingState(isRecording: isRecording)
        isRecording ? player.play() : player.pause()
    }

    // MARK: - IBActions

    @IBAction func didTapToggleMic(_ sender: Any) {
        createDuetViewModel.toggleMic()
    }
}

// MARK: - Configuration

extension CreateDuetViewController {
    private func setupPlayer() {
        playerLayer.videoGravity = .resizeAspectFill
        originalStoryView.layer.insertSublayer(playerLayer, at: 0)
        playerLayer.frame = originalStoryView.bounds
        player.automaticallyWaitsToMinimizeStalling = false

    }
}

// MARK: - Private methods

extension CreateDuetViewController {


    private func togglePlay(isPlaying: Bool) {
        isPlaying ? player.play() : player.pause()
    }

    private func updatePlayerAsset() {
        guard let asset = createDuetViewModel.originAsset else {
            return
        }
        let playerItem = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: playerItem)
        let recordedTime = createDuetViewModel.recordedDurations.reduce(0, +)
        player.seek(to: CMTime(seconds: recordedTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
    }

    private func updateMicButtonState(isMicEnabled: Bool) {
        let image = isMicEnabled ? R.image.ic_stories_mic_on() : R.image.ic_stories_mic_off()
        micButton.setImage(image, for: .normal)
    }
}

// MARK: -

extension CreateDuetViewController {

}
