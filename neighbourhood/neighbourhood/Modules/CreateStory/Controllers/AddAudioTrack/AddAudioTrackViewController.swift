//
//  AddAudioTrackViewController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 11.02.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import UIKit
import AVFoundation

class AddAudioTrackViewController: BaseViewController {

    @IBOutlet weak var hashtagsTextView: HashtagsTextView!
    @IBOutlet weak var audioTrackSlider: AudioTrackSlider!
    @IBOutlet weak var nonHashtagsView: UIStackView!
    @IBOutlet weak var saveButton: LightButton!

    private let viewModel: AddAudioTrackViewModel
    private let audioPlayer = AVPlayer()
    private var timeObserver: Any?
    private var maxSeconds: Double = 0

    init(audioTrackURL: URL) {
        self.viewModel = .init(audioTrackURL: audioTrackURL)
        super.init(nibName: nil, bundle: nil)
    }

    deinit {
        if let timeObserver = timeObserver {
            audioPlayer.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPlayer()
        setupAudioSlider()
        setupHashtagsTextView()
        setupViewModel()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        audioPlayer.pause()
    }

    @IBAction func didTapApply(_ sender: Any) {

    }

    @IBAction func didTapSave(_ sender: Any) {
        save()
    }

    @IBAction func didTapClose(_ sender: Any) {
        confirmCancel()
    }
}

// MARK: Configuration

extension AddAudioTrackViewController {
    private func setupViewModel() {
        viewModel.$isSending.bind { [weak self] (isSending) in
            self?.saveButton.isLoading = isSending
        }
        viewModel.$startSecond.bind { [weak self] (seconds) in
            self?.audioTrackSlider.startSecond = seconds
            self?.audioPlayer.seek(to: CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
        }
        viewModel.$saveResult.bind { [weak self] (result) in
            guard let result = result else {
                return
            }
            self?.handleResult(result)
        }
        viewModel.$descriptionError.bind { [weak self] (error) in
            self?.hashtagsTextView.error = error
        }
    }

    private func setupAudioSlider() {
        audioTrackSlider.delegate = self
        audioTrackSlider.audio = AVAsset(url: viewModel.audioTrackURL)
    }

    private func setupHashtagsTextView() {
        hashtagsTextView.title = R.string.localizable.storyDescriptionTitle()
        hashtagsTextView.placeholder = R.string.localizable.postDescriptionPlaceholder()
        hashtagsTextView.delegate = self
    }

    private func setupPlayer() {
        let soundItem = AVPlayerItem(url: viewModel.audioTrackURL)
        maxSeconds = max(soundItem.asset.duration.seconds - 5, 0)
        audioPlayer.replaceCurrentItem(with: soundItem)
        timeObserver = audioPlayer.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.01, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: .main, using: { [weak self] (time) in
            guard let self = self else {
                return
            }
            self.audioTrackSlider.currentSecond = time.seconds
            if time.seconds == self.audioPlayer.currentItem?.duration.seconds {
                self.audioPlayer.seek(to: CMTime(seconds: self.viewModel.startSecond, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
            }
        })
    }

}

// MARK: Private methods

extension AddAudioTrackViewController {
    private func close() {
        CreateStoryRouter(in: navigationController).returnToMyTracks()
    }

    private func confirmCancel() {
        Alert(title: nil, message: Alert.Message.cancelChanges)
            .configure(doneText: Alert.Action.ok)
            .configure(cancelText: Alert.Action.cancel)
            .show { [weak self] (result) in
                if result == .done {
                    self?.close()
                }
            }
    }

    private func save() {
        viewModel.setDescription(hashtagsTextView.textIsEmpty ? "" : hashtagsTextView.text)
        viewModel.save()
    }

    private func handleResult(_ result: Result<Void, Error>) {
        switch result {
        case .failure(let error):
            handleError(error)
        case .success:
            Toast.show(message: Alert.Message.audioTrackSaved)
            close()
        }
    }
}

// MARK: AudioTrackSliderDelegate

extension AddAudioTrackViewController: AudioTrackSliderDelegate {
    func startSecondChanged(_ second: Double) {
        if second > maxSeconds {
            viewModel.changeStartSecond(maxSeconds)
            Toast.show(message: R.string.localizable.audioTrackVideoTooShort())
            return
        }
        viewModel.changeStartSecond(second)
    }

    func playStateChanged(isPlaying: Bool) {
        isPlaying ? audioPlayer.play() : audioPlayer.pause()
    }
}

// MARK: AudioTrackSliderDelegate

extension AddAudioTrackViewController: HashtagsTextViewDelegate {
    func hashtagsListToggle(isShown: Bool) {
        nonHashtagsView.isHidden = isShown
    }
    func editingEnded() {
    }
}
