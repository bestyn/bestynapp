//
//  RecordVoiceViewController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 26.03.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import UIKit

class RecordVoiceViewController: BaseViewController {

    @IBOutlet weak var recordTimerLabel: UILabel!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var recordedButtonsView: UIStackView!
    @IBOutlet weak var playViews: UIStackView!
    @IBOutlet weak var totalRecordedDirationLabel: UILabel!
    @IBOutlet weak var collapseButton: UIButton!
    @IBOutlet weak var audioTrackSlider: AudioTrackSlider! {
        didSet {
            audioTrackSlider.delegate = self
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    let viewModel = RecordVoiceViewModel.shared

    private lazy var animationCircles: [UIView] = {
        var circles: [UIView] = []
        for _ in 0..<2 {
            let circle = UIView()
            recordButton.insertSubview(circle, at: 0)
            circle.translatesAutoresizingMaskIntoConstraints = false
            circle.heightAnchor.constraint(equalToConstant: 100).isActive = true
            circle.widthAnchor.constraint(equalToConstant: 100).isActive = true
            circle.centerXAnchor.constraint(equalTo: recordButton.centerXAnchor).isActive = true
            circle.centerYAnchor.constraint(equalTo: recordButton.centerYAnchor).isActive = true
            circle.cornerRadius = 50
            circle.backgroundColor = R.color.purpleLight()?.withAlphaComponent(0.5)
            circles.append(circle)
            circle.isUserInteractionEnabled = false
        }
        return circles
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        NotificationCenter.default.addObserver(self, selector: #selector(handleAudioProgress(_:)), name: .audioTrackProgress, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAudioPaused(_:)), name: .audioTrackPaused, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.stop()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @IBAction func didTapToggleRecord(_ sender: Any) {
        viewModel.toggleRecord()
    }

    @IBAction func didTapDeleteRecorded(_ sender: Any) {
        viewModel.removeRecorded()
    }

    @IBAction func didTapTogglePlay(_ sender: Any) {
        viewModel.togglePlay()
    }

    @IBAction func didTapConfirm(_ sender: Any) {
        viewModel.confirm()
        navigationController?.popViewController(animated: true)
    }

    @IBAction func didTapBackButton(_ sender: Any) {
        viewModel.reset()
        navigationController?.popViewController(animated: true)
    }

    @IBAction func didTapCollapse(_ sender: Any) {
        MyPostsRouter(in: navigationController).collapseVoiceRecording()
    }
}

// MARK: - Configuration

extension RecordVoiceViewController {
    private func setupViewModel() {
        viewModel.$recordState.bind { [weak self] (state) in
            self?.handleRecordState(state)
        }
        viewModel.$recordDuration.bind { [weak self] (duration) in
            self?.recordTimerLabel.text = self?.formatRecordedDuration(duration)
        }
    }
}

// MARK: - Private methods

extension RecordVoiceViewController {

    private func handleRecordState(_ state: RecordVoiceViewModel.State) {
        collapseButton.isHidden = true
        switch state {
        case .idle:
            recordTimerLabel.textColor = R.color.accentGreen()
            recordButton.setImage(R.image.ic_record_post_audio(), for: .normal)
            recordButton.isHidden = false
            recordedButtonsView.isHidden = true
            playViews.isHidden = true
        case .recording:
            recordTimerLabel.textColor = .white
            recordButton.setImage(R.image.ic_record_post_audio_stop(), for: .normal)
            startRecordAnimation()
            collapseButton.isHidden = false
        case .recorded:
            if let url = viewModel.recordedURL {
                audioTrackSlider.audio = .init(url: url)
            }
            recordTimerLabel.text = formatRecordedDuration(0)
            totalRecordedDirationLabel.text = formatRecordedDuration(viewModel.recordDuration)
            recordButton.isHidden = true
            recordedButtonsView.isHidden = false
            playPauseButton.setImage(R.image.ic_record_post_audio_play(), for: .normal)
            playViews.isHidden = false
            stopRecordAnimation()
        case .playing:
            playPauseButton.setImage(R.image.ic_record_post_audio_pause(), for: .normal)
        }
    }

    private func formatRecordedDuration(_ duration: Double) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    @objc private func handleAudioProgress(_ notification: Notification) {
        guard let playerInfo = notification.object as? (URL, Double),
              playerInfo.0 == viewModel.recordedURL else {
            return
        }
        recordTimerLabel.text = formatRecordedDuration(playerInfo.1)
        audioTrackSlider.currentSecond = playerInfo.1
    }

    @objc private func handleAudioPaused(_ notification: Notification) {
        guard let playerInfo = notification.object as? URL,
              playerInfo == viewModel.recordedURL else {
            return
        }
        playPauseButton.setImage(R.image.ic_record_post_audio_play(), for: .normal)
    }

    private func startRecordAnimation() {
        guard animationCircles.count > 0 else {
            return
        }
        animationCircles.forEach({ circle in
            circle.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            circle.alpha = 1
            circle.layer.removeAllAnimations()
        })
        let duration = 2.0
        let delay = 0.5
        for (index, circle) in animationCircles.enumerated() {
            UIView.animate(withDuration: duration, delay: delay * Double(index), options: [.repeat], animations: {
                circle.transform = CGAffineTransform(scaleX: 1.9, y: 1.9)
                    circle.alpha = 0
                }, completion: { _ in
                    circle.transform = .identity
                    circle.alpha = 1
                })
        }
    }

    private func stopRecordAnimation() {
        animationCircles.forEach({ circle in
            circle.transform = .identity
            circle.alpha = 0
            circle.layer.removeAllAnimations()
        })
    }
}

extension RecordVoiceViewController: AudioTrackSliderDelegate {
    func startSecondChanged(_ second: Double) {
        viewModel.seekPlayer(second: second)
    }

    func playStateChanged(isPlaying: Bool) {
    }


}
