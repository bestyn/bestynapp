//
//  AudioTrackSlider.swift
//  neighbourhood
//
//  Created by Artem Korzh on 03.02.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import UIKit
import AVFoundation

protocol AudioTrackSliderDelegate: class {
    func startSecondChanged(_ second: Double)
    func playStateChanged(isPlaying: Bool)
}

class AudioTrackSlider: UIView {

    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var audioVisualisationView: AudioVisualisationView!
    @IBOutlet weak var handleView: UIView!
    @IBOutlet weak var totalLengthLabel: UILabel!
    @IBOutlet weak var currentPositionLabel: UILabel!
    @IBOutlet weak var handleIndicatorView: UIView!

    @IBInspectable public var withPlayButton: Bool = true {
        didSet { playButton.isHidden = !withPlayButton }
    }

    @IBInspectable public var withTotalDuration: Bool = true {
        didSet { totalLengthLabel.isHidden = !withTotalDuration }
    }

    @IBInspectable public var handleColor: UIColor = R.color.blueButton()! {
        didSet { handleIndicatorView.backgroundColor = handleColor }
    }

    @IBInspectable public var handleTimeColor: UIColor = R.color.blueButton()! {
        didSet { currentPositionLabel.textColor = handleTimeColor }
    }

    @IBInspectable public var activeColor: UIColor {
        get { audioVisualisationView.activeColor }
        set { audioVisualisationView.activeColor = newValue }
    }

    @IBInspectable public var baseColor: UIColor {
        get { audioVisualisationView.baseColor }
        set { audioVisualisationView.baseColor = newValue }
    }

    @IBInspectable public var visualizeFromStart: Bool = false {
        didSet { setVisualisationStart() }
    }

    public var audio: AVAsset! {
        didSet {
            if isViewSet {
                updateCurrentAudio()
            }
        }
    }

    public var startSecond: Double {
        get { _startSecond }
        set {
            _startSecond = newValue
            moveHandle()
            setVisualisationStart()

        }
    }

    public var currentSecond: Double = 0 {
        didSet { updateVisualisation() }
    }
    public weak var delegate: AudioTrackSliderDelegate?

    private var pps: CGFloat?
    private var _startSecond: Double = 0
    private var isPlaying = false {
        didSet {
            togglePlayState()
            delegate?.playStateChanged(isPlaying: isPlaying)
        }
    }
    private var timeObserver: Any?
    private var isViewSet = false

    private var maxWidth: CGFloat { frame.width - (withPlayButton ? 51 : 0) - (withTotalDuration ? 47 : 0) }


    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }

    private func initView() {
        loadFromXib(R.nib.audioTrackSlider.name, contextOf: AudioTrackSlider.self)
        setupGestures()
        playButton.isHidden = !withPlayButton
        totalLengthLabel.isHidden = !withTotalDuration
        handleIndicatorView.backgroundColor = handleColor
        currentPositionLabel.textColor = handleTimeColor
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        isViewSet = true
        updateCurrentAudio()
    }

    @IBAction func didTapTogglePlay(_ sender: Any) {
        isPlaying.toggle()
    }

    public func pause() {
        if isPlaying {
            isPlaying = false
        }
    }

    public func play() {
        if !isPlaying {
            isPlaying = true
        }
    }

    private func updateCurrentAudio() {
        guard let audio = self.audio else {
            return
        }
        audio.loadValuesAsynchronously(forKeys: ["duration"]) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else {
                    return
                }
                self.pps = self.maxWidth / max(CGFloat(audio.duration.seconds), 0.1)
                self.setVisualisationStart()
                self.moveHandle()
                self.totalLengthLabel.text = audio.duration.seconds.displayTime
            }
        }
    }

    private func moveHandle() {
        guard let pps = pps, pps != .infinity else {
            return
        }
        handleView.center = CGPoint(x: pps * CGFloat(startSecond), y: handleView.superview!.bounds.height / 2)
        currentPositionLabel.center = CGPoint(x: pps * CGFloat(startSecond), y: currentPositionLabel.superview!.bounds.height / 2)
        currentPositionLabel.text = _startSecond.displayTime
        currentPositionLabel.setNeedsLayout()
        currentPositionLabel.layoutIfNeeded()
    }

    private func setupGestures() {
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleFrameMove(recognizer:)))
        handleView.addGestureRecognizer(panRecognizer)
        handleView.isUserInteractionEnabled = true
    }

    @objc private func handleFrameMove(recognizer: UIPanGestureRecognizer) {
        let min = audioVisualisationView.frame.minX
        let max = audioVisualisationView.frame.maxX
        let translation = recognizer.translation(in: self)
        var finalPosition = handleView.center.x + translation.x
        if finalPosition < min {
            finalPosition = min
        } else if finalPosition > max {
            finalPosition = max
        }
        handleView.center = CGPoint(x: finalPosition, y: handleView.superview!.bounds.height / 2)
        currentPositionLabel.center = CGPoint(x: finalPosition, y: currentPositionLabel.superview!.bounds.height / 2)
        recognizer.setTranslation(.zero, in: self)
        if let pps = pps {
            _startSecond = Double(finalPosition / pps)
            currentPositionLabel.text = _startSecond.displayTime
            currentPositionLabel.setNeedsLayout()
            currentPositionLabel.layoutIfNeeded()
            if recognizer.state == .ended {
                delegate?.startSecondChanged(_startSecond)
                setVisualisationStart()
            }
        }
    }

    private func togglePlayState() {
        if isPlaying {
            playButton.setImage(R.image.ic_audio_track_pause(), for: .normal)
        } else {
            playButton.setImage(R.image.ic_audio_track_play(), for: .normal)
        }
    }

    private func setVisualisationStart() {
        guard let pps = pps, pps != .infinity else {
            return
        }
        audioVisualisationView.min = (visualizeFromStart ? 0 : CGFloat(startSecond)) * pps / maxWidth
    }

    private func updateVisualisation() {
        guard let pps = pps else {
            return
        }
        audioVisualisationView.max = CGFloat(currentSecond) * pps / maxWidth
    }

}
