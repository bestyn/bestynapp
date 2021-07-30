//
//  RemovableAudioView.swift
//  neighbourhood
//
//  Created by Artem Korzh on 30.03.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import UIKit

protocol RemovableAudioViewDelegate: class {
    func audioRemoved(url: URL)
}

class RemovableAudioView: UIView {

    lazy var audioSlider: AudioTrackSlider = {
        let slider = AudioTrackSlider()
        slider.delegate = self
        return slider
    }()

    lazy var removeButton: UIButton = {
        let button = UIButton()
        button.setImage(R.image.remove_image_button(), for: .normal)
        button.addTarget(self, action: #selector(didTapDownload), for: .touchUpInside)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 24),
            button.heightAnchor.constraint(equalToConstant: 24)
        ])
        return button
    }()

    private weak var audioService = AudioPlayerService.shared

    private lazy var backgroundLayer: CAShapeLayer = {
        let backgroundLayer = CAShapeLayer()
        backgroundLayer.strokeColor = R.color.greyLight()?.cgColor
        backgroundLayer.lineWidth = 1
        backgroundLayer.fillColor = UIColor.clear.cgColor
        layer.addSublayer(backgroundLayer)
        return backgroundLayer
    }()

    public var url: URL! {
        didSet { audioSlider.audio = .init(url: url) }
    }
    public weak var delegate: RemovableAudioViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }

    private func initView() {
        let stackView = UIStackView(arrangedSubviews: [audioSlider, removeButton])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 10
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        ])

        NotificationCenter.default.addObserver(self, selector: #selector(handleAudioServicePause(_:)), name: .audioTrackPaused, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAudioServiceProgress(_:)), name: .audioTrackProgress, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundLayer.frame = bounds
        backgroundLayer.path = UIBezierPath.verticalSymmetricShape(bounds: bounds, leftRadius: bounds.height / 2, rightRadius: 10).cgPath
    }

    @objc private func didTapDownload() {
        delegate?.audioRemoved(url: url)
    }

    @objc private func handleAudioServicePause(_ notification: Notification) {
        guard let playerURL = notification.object as? URL,
              playerURL == url else {
            return
        }
        audioSlider.pause()
    }

    @objc private func handleAudioServiceProgress(_ notification: Notification) {
        guard let playerInfo = notification.object as? (URL, Double),
              playerInfo.0 == url else {
            return
        }
        audioSlider.currentSecond = playerInfo.1
    }
}

extension RemovableAudioView: AudioTrackSliderDelegate {
    func startSecondChanged(_ second: Double) {
        audioService?.seek(url: url, to: second)
    }

    func playStateChanged(isPlaying: Bool) {
        isPlaying ? audioService?.play(url: url) : audioService?.pause()
    }
}
