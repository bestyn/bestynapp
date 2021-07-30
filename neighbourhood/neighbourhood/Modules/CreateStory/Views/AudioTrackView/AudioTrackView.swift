//
//  AudioTrackView.swift
//  neighbourhood
//
//  Created by Artem Korzh on 28.01.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import UIKit

protocol AudioTrackViewDelegate: class {
    func trackFavoriteToggled(track: AudioTrackModel)
    func trackMorePressed(track: AudioTrackModel)
}

class AudioTrackView: UIView {

    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!

    public var audioTrack: AudioTrackModel! {
        didSet { updateTrackInfo() }
    }

    public var isPlaying = false {
        didSet {
            updatePlayState()
        }
    }

    public weak var delegate: AudioTrackViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }

    @IBAction func didTapTogglePlay(_ sender: Any) {
        isPlaying.toggle()
        if isPlaying {
            AudioPlayerService.shared.play(url: audioTrack.url)
        } else {
            AudioPlayerService.shared.pause()
        }
    }

    @IBAction func didTapFavorite(_ sender: Any) {
        delegate?.trackFavoriteToggled(track: audioTrack)
    }

    @IBAction func didTapMore(_ sender: Any) {
        delegate?.trackMorePressed(track: audioTrack)
    }


    private func initView() {
        loadFromXib(R.nib.audioTrackView.name, contextOf: AudioTrackView.self)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAudioServicePlaying(_:)), name: .audioTrackPlaying, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAudioServicePaused(_:)), name: .audioTrackPaused, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        if isPlaying {
            AudioPlayerService.shared.pause()
        }
    }

    private func updateTrackInfo() {
        descriptionLabel.text = audioTrack.description
        durationLabel.text = durationString(duration: audioTrack.duration)
        authorLabel.text = "added by \(audioTrack.profile?.fullName ?? Configuration.appName)"
        favoriteButton.tintColor = audioTrack.isFavorite ? R.color.blueButton() : R.color.greyBackground()
        isPlaying = AudioPlayerService.shared.currentURL == audioTrack.url && AudioPlayerService.shared.isPlaying
    }

    private func durationString(duration: Int) -> String {
        let seconds = duration % 60
        let minutes = duration / 60
        if minutes > 0, seconds > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        }
        if seconds == 0 {
            return String(format: "%dm", minutes)
        }
        return String(format: "%ds", seconds)
    }

    private func updatePlayState() {
        let image = isPlaying ? R.image.ic_audio_track_pause() : R.image.ic_audio_track_play()
        playButton.setImage(image, for: .normal)
    }

    @objc private func handleAudioServicePlaying(_ notification: Notification) {
        guard let audioURL = notification.object as? URL,
              audioURL == audioTrack.url else {
            return
        }
        isPlaying = true
    }

    @objc private func handleAudioServicePaused(_ notification: Notification) {
        guard let audioURL = notification.object as? URL,
              audioURL == audioTrack.url else {
            return
        }
        isPlaying = false
    }
}
