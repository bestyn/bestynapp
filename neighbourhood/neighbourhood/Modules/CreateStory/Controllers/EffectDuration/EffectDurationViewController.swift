//
//  EffectDurationViewController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 19.01.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import UIKit
import AVFoundation

class EffectDurationViewController: UIViewController {

    @IBOutlet weak var videoPreviewView: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var videoSlider: VideoSlider!
    @IBOutlet weak var contentContainerView: UIView!

    public let viewModel: EffectDurationViewModel
    private var viewRanges: [UIView: ClosedRange<Double>] = [:]

    private let player = AVPlayer()
    private lazy var playerLayer = AVPlayerLayer(player: player)
    private var isPlaying = false {
        didSet { updatePlayingState() }
    }

    private var timeObserver: Any?
    private var isDragging = false

    init(textEntity: StoryCreator.TextEntity) {
        viewModel = EffectDurationViewModel(entity: textEntity)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        player.pause()
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        debugPrint("deinit \(name)")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPlayer()
        setupViewModel()
        setupVideoSlider()
        setupBackground()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupContentContainer()
        playerLayer.frame = videoPreviewView.bounds
    }

    @IBAction func didTapTogglePlay(_ sender: Any) {
        isPlaying.toggle()
    }

    @IBAction func didTapCancel(_ sender: Any) {
        askForCancel()
    }

    @IBAction func didTapDone(_ sender: Any) {
        confirmEdit()
    }
}

// MARK: - Configuration

extension EffectDurationViewController {

    private func setupPlayer() {
        playerLayer.videoGravity = .resizeAspectFill
        videoPreviewView.layer.addSublayer(playerLayer)
        let time = CMTime(seconds: 0.01, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: time, queue: .main) { [weak self] (time) in
            guard let self = self, self.player.rate != 0 else {
                return
            }
            self.viewRanges.forEach { (view, range) in
                view.isHidden = !range.contains(time.seconds)
            }
            if time.seconds >= self.player.currentItem!.duration.seconds {
                self.player.pause()
                self.player.seek(to: CMTime(seconds: 0, preferredTimescale: 1), toleranceBefore: .zero, toleranceAfter: .zero)
                self.player.play()
                return
            }
            self.videoSlider.frameTime = time
        }
    }

    private func setupContentContainer() {
        let scale = videoPreviewView.bounds.height / contentContainerView.bounds.height
        contentContainerView.subviews.forEach { (view) in
            view.center = contentContainerView.center
        }
        contentContainerView.transform = CGAffineTransform(scaleX: scale, y: scale)
        contentContainerView.center = videoPreviewView.center
    }

    private func setupViewModel() {
        viewModel.$assetParams.bind { [weak self] (params) in
            self?.updatePlayerParams(params)
            self?.updateVideoSlider()
        }
        viewModel.$texts.bind { [weak self] (texts) in
            self?.updateTexts(texts: texts)
        }
        viewModel.$currentEntity.bind { [weak self] (entity) in
            self?.updateVideoSlider()
        }
    }

    private func setupVideoSlider() {
        videoSlider.delegate = self
    }

    private func setupBackground() {
        guard viewModel.isTextMode else {
            return
        }
        contentContainerView.layer.insertSublayer(viewModel.backgroundLayer, at: 0)
        viewModel.backgroundLayer.frame = contentContainerView.bounds.insetBy(dx: contentContainerView.bounds.width / -2, dy: contentContainerView.bounds.height / -2)
    }
}

// MARK: - Private methods

extension EffectDurationViewController {
    private func updatePlayingState() {
        isPlaying ? player.play() : player.pause()
        playButton.setImage(isPlaying ? R.image.stories_pause_small_icon() : R.image.stories_play_small_icon(), for: .normal)
    }

    private func updatePlayerParams(_ params: VideoAssetParams) {
        let item = AVPlayerItem(asset: params.asset)
        item.videoComposition = params.videoComposition
        player.pause()
        player.replaceCurrentItem(with: item)
        self.isPlaying = true
    }

    private func updateVideoSlider() {
        let params = viewModel.assetParams
        let range = viewModel.currentEntity.range
        let assetParams = VideoAssetParams(
            asset: params.asset,
            videoComposition: viewModel.isTextMode ? params.layerComposition : params.videoComposition,
            layerComposition: nil,
            audioMix: nil)
        self.videoSlider.params = .init(assetParams: assetParams, range: range)
    }

    private func updateTexts(texts: [StoryCreator.TextEntity]) {
        contentContainerView.subviews.forEach({ $0.removeFromSuperview() })
        contentContainerView.transform = .identity
        viewRanges = [:]
        for text in texts {
            let textView = HighlightTextView(textEditorEntity: text.editorEntity)
            textView.contentOffset = .zero
            textView.setSizeInScreen()
            let imageView = UIImageView(image: textView.screenshot)
            contentContainerView.addSubview(imageView)
            imageView.center = contentContainerView.center
            imageView.transform = text.transform
            viewRanges[imageView] = text.range
        }
        setupContentContainer()
    }

    private func askForCancel() {
        Alert(title: nil, message: Alert.Message.cancelChanges)
            .configure(doneText: Alert.Action.ok)
            .configure(cancelText: Alert.Action.cancel)
            .show { [weak self] (result) in
                if result == .done {
                    self?.close()
                }
            }
    }

    private func confirmEdit() {
        viewModel.confirmEdit()
        close()
    }

    private func close() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - VideoSliderDelegate

extension EffectDurationViewController: VideoSliderDelegate {
    func rangeChanged(_ range: ClosedRange<Double>) {
    }

    func frameChanged(second: Double) {
        player.seek(to: CMTime(seconds: second, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
    }

    func dragStarted() {
        player.pause()
    }

    func dragEnded() {
        if isPlaying {
            player.play()
        }
        viewModel.updateDuration(range: videoSlider.range)
    }
}
