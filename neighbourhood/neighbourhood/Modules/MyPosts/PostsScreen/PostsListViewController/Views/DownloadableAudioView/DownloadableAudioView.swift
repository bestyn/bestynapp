//
//  DownloadableAudioView.swift
//  neighbourhood
//
//  Created by Artem Korzh on 31.03.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import UIKit

protocol DownloadableAudioViewDelegate: class {
    func audioPlayed(url: URL)
}

class DownloadableAudioView: UIView {

    lazy var audioSlider: AudioTrackSlider = {
        let slider = AudioTrackSlider()
        slider.activeColor = R.color.mainBlack()!
        slider.baseColor = R.color.greyLight()!
        slider.delegate = self
        return slider
    }()

    lazy var downloadButton: UIButton = {
        let button = UIButton()
        button.setImage(R.image.ic_audio_download(), for: .normal)
        button.addTarget(self, action: #selector(didTapDownload), for: .touchUpInside)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 30),
            button.heightAnchor.constraint(equalToConstant: 30)
        ])
        return button
    }()

    lazy var counterLabel: UILabel = {
        let label = UILabel()
        label.font = R.font.poppinsRegular(size: 12)
        label.textColor = R.color.mainBlack()
        label.widthAnchor.constraint(equalToConstant: 32).isActive = true
        return label
    }()

    lazy var extraStackView: UIStackView = {
        let divider = UIView()
        divider.backgroundColor = R.color.greyBackground()
        NSLayoutConstraint.activate([
            divider.widthAnchor.constraint(equalToConstant: 1),
            divider.heightAnchor.constraint(equalToConstant: 14),
        ])
        let iconImageView = UIImageView(image: R.image.ic_listen_count())
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 14),
            iconImageView.heightAnchor.constraint(equalToConstant: 14)
        ])
        let counterStackView = UIStackView(arrangedSubviews: [divider, iconImageView, counterLabel])
        counterStackView.spacing = 10
        counterStackView.axis = .horizontal
        counterStackView.alignment = .center
        let stackView = UIStackView(arrangedSubviews: [counterStackView, downloadButton])
        stackView.spacing = 10
        stackView.axis = .horizontal
        return stackView
    }()

    private weak var audioService = AudioPlayerService.shared
    private var hasPlayed = false

    public var url: URL! {
        didSet {
            hasPlayed = true
            audioSlider.audio = .init(url: url)
            if url == audioService?.currentURL {
                audioSlider.play()
            }
        }
    }
    public var listenCount: Int = 0 {
        didSet { counterLabel.text = listenCount.counter() }
    }

    public weak var delegate: DownloadableAudioViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }

    private func initView() {
        let stackView = UIStackView(arrangedSubviews: [audioSlider, extraStackView])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 5
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
        ])

        NotificationCenter.default.addObserver(self, selector: #selector(handleAudioServicePause(_:)), name: .audioTrackPaused, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAudioServiceProgress(_:)), name: .audioTrackProgress, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAudioServicePlay(_:)), name: .audioTrackPlaying, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func didTapDownload() {
        DownloadService.saveAudioToFiles(audioURL: url)
    }

    @objc private func handleAudioServicePause(_ notification: Notification) {
        guard let playerURL = notification.object as? URL,
              playerURL == url else {
            return
        }
        audioSlider.pause()
    }

    @objc private func handleAudioServicePlay(_ notification: Notification) {
        guard let playerURL = notification.object as? URL,
              playerURL == url else {
            return
        }
        audioSlider.play()
    }

    @objc private func handleAudioServiceProgress(_ notification: Notification) {
        guard let playerInfo = notification.object as? (URL, Double),
              playerInfo.0 == url else {
            return
        }
        audioSlider.currentSecond = playerInfo.1
    }
}

extension DownloadableAudioView: AudioTrackSliderDelegate {
    func startSecondChanged(_ second: Double) {
        audioService?.seek(url: url, to: second)
    }

    func playStateChanged(isPlaying: Bool) {
        isPlaying ? audioService?.play(url: url) : audioService?.pause()
        if hasPlayed, isPlaying {
            hasPlayed = true
            delegate?.audioPlayed(url: url)
        }
    }
}
