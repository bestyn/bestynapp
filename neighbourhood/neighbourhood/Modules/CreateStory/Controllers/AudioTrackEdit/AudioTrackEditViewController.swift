//
//  AudioTrackEditViewController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 03.02.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import UIKit

protocol AudioTrackEditViewControllerDelegate: class {
    func startPositionChanged(seconds: Double)
    func changeTrack()
    func confirmChanges()
}

class AudioTrackEditViewController: UIViewController, BottomMenuPresentable {

    var transitionManager: BottomMenuPresentationManager! = .init()
    var presentedViewHeight: CGFloat { contentView.bounds.height }

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var trackDescriptionLabel: UILabel!
    @IBOutlet weak var audioTrackSlider: AudioTrackSlider!

    private let track: StoryCreator.AudioTrack
    private var seconds: Double
    private var changeTrackRange: NSRange?

    public weak var delegate: AudioTrackEditViewControllerDelegate?
    public var currentSecond: Double = 0 {
        didSet {
            audioTrackSlider.currentSecond = seconds + currentSecond.truncatingRemainder(dividingBy: track.asset.duration.seconds - seconds)
        }
    }

    init(track: StoryCreator.AudioTrack) {
        self.track = track
        seconds = track.startsAt
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTrackSlider()
        setupDescriptionLabel()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        audioTrackSlider.pause()
    }

    @IBAction func didTapDone(_ sender: Any) {
        done()
    }

    private func done() {
        delegate?.confirmChanges()
    }

    @objc public func close() {
        dismiss(animated: true)
    }
}

extension AudioTrackEditViewController {
    private func setupTrackSlider() {
        audioTrackSlider.withPlayButton = false
        audioTrackSlider.audio = track.asset
        audioTrackSlider.startSecond = track.startsAt
        audioTrackSlider.currentSecond = track.startsAt
        audioTrackSlider.delegate = self
    }

    private func setupDescriptionLabel() {
        let attributedText = NSMutableAttributedString(string: track.track.description, attributes: [
            .foregroundColor: R.color.mainBlack(),
            .font: R.font.poppinsRegular(size: 13)
        ])
        let changeButton = NSAttributedString(string: " Change track", attributes: [
            .foregroundColor: R.color.blueButton(),
            .font: R.font.poppinsRegular(size: 13)
        ])
        attributedText.append(changeButton)
        changeTrackRange = NSString(string: attributedText.string).range(of: changeButton.string)
        
        trackDescriptionLabel.attributedText = attributedText
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first,
           let changeTrackRange = changeTrackRange,
           trackDescriptionLabel.frame.contains(touch.location(in: view)),
           trackDescriptionLabel.check(touch: touch, isInRange: changeTrackRange) {
            delegate?.changeTrack()
        }
    }
}

// MARK: - AudioTrackSliderDelegate

extension AudioTrackEditViewController: AudioTrackSliderDelegate {
    func startSecondChanged(_ second: Double) {
        if track.asset.duration.seconds - second < 5 {
            audioTrackSlider.startSecond = min(0, track.asset.duration.seconds - 5)
            seconds = audioTrackSlider.startSecond
            delegate?.startPositionChanged(seconds: audioTrackSlider.startSecond)
            Toast.show(message: R.string.localizable.audioTrackVideoTooShort())
            return
        }
        seconds = second
        delegate?.startPositionChanged(seconds: second)
    }

    func playStateChanged(isPlaying: Bool) {
    }
}
