//
//  BaseChatVoiceCell.swift
//  neighbourhood
//
//  Created by Artem Korzh on 02.09.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import SoundWave

class BaseChatVoiceCell: BaseChatCell {

    @IBOutlet private weak var audioView: AudioVisualizationView!
    @IBOutlet private weak var playButton: UIButton!
    @IBOutlet private weak var soundDurationLabel: UILabel!

    private(set) var audioURL: URL?
    private var type: SoundAction = .play
    private var isFetchingAudio = false
    private let viewModel = VoiceMessageManager()

    private var seconds = 0

    override func setupSpecificView() {
        audioView.audioVisualizationMode = .read
        var array = [Float]()
        for _ in 0...50 {
            array.append(Float.random(in: 0..<1))
        }

        audioView.meteringLevels = array

        NotificationCenter.default.addObserver(self, selector: #selector(handleVoiceStart(notification:)), name: .startPlayingVoiceMessage, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleVoiceEnd(notification:)), name: .stopPlayingVoiceMessage, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleVoicePaused(notification:)), name: .pausePlayingVoiceMessage, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleVoiceTimer(notification:)), name: .timerPlayingVoiceMessage, object: nil)
    }

    override func resetView() {
        seconds = 0
        audioView.gradientEndColor = R.color.greyLight()!
        updateMessageDuration()
        playButton.setImage(R.image.play_icon(), for: .normal)
        self.audioView.stop()
    }

    override func fillSpecificData(from message: PrivateChatMessageModel) {
        playButton.setImage(R.image.play_icon(), for: .normal)
        audioURL = message.attachment?.origin
        updateMessageDuration()
        checkPlayingState()
    }

    private func checkPlayingState() {
        if VoiceMessageManager.shared.audioURL == audioURL, VoiceMessageManager.shared.isPlaying {
            audioView.gradientEndColor = .white
            audioView.play(for: VoiceMessageManager.shared.leftDuration)
            playButton.setImage(R.image.pause_icon(), for: .normal)
        }
    }

    private func updateMessageDuration() {
        VoiceMessageManager.shared.getAudioDuration(url: audioURL) { (time) in
            if let duration = time?.timeInterval?.displayTime {
                self.soundDurationLabel.text = duration
            }
        }
    }

    @objc private func handleVoiceStart(notification: Notification) {
        if let data = notification.object as? (URL?, TimeInterval),
            data.0 == audioURL {
            DispatchQueue.main.async {
                self.audioView.gradientEndColor = .white
                self.audioView.play(for: data.1)
                self.playButton.setImage(R.image.pause_icon(), for: .normal)
            }
        }
    }

    @objc private func handleVoiceEnd(notification: Notification) {
        if let url = notification.object as? URL,
            url == audioURL {
            DispatchQueue.main.async {
                self.playButton.setImage(R.image.play_icon(), for: .normal)
                self.audioView.stop()
            }
        }
    }

    @objc private func handleVoicePaused(notification: Notification) {
        if let url = notification.object as? URL,
            url == audioURL {
            DispatchQueue.main.async {
                self.playButton.setImage(R.image.play_icon(), for: .normal)
                self.audioView.pause()
            }
        }
    }

    @objc private func handleVoiceTimer(notification: Notification) {
        if let data = notification.object as? (URL?, TimeInterval),
            data.0 == audioURL {
            DispatchQueue.main.async {
                self.soundDurationLabel.text = data.1.displayTime
            }
        }
    }

//
//    public func playAudioButtonDidTap() {
//        audioView.gradientEndColor = .white
//
//        switch type {
//        case .pause:
//            type = .play
//            playButton.setImage(R.image.pause_icon(), for: .normal)
//            if let audioURL = self.audioUrl {
//                VoiceMessageManager.shared.togglePlay(audioURL: audioURL)
//            }
//        case .play:
//            type = .pause
//            playButton.setImage(R.image.play_icon(), for: .normal)
//        }
//    }
}
