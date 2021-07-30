//
//  ClipAdjustmentViewController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 23.12.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import AVFoundation

protocol ClipAdjustmentViewControllerDelegate: class {
    func adjustmentsComplete()
}

class ClipAdjustmentViewController: BaseViewController {

    @IBOutlet weak var videoContainerView: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var videoSlider: VideoSlider! {
        didSet { videoSlider.delegate = viewModel }
    }
    @IBOutlet weak var singleClipEditControlsView: UIStackView!
    @IBOutlet weak var clipsCollectionView: UICollectionView!
    @IBOutlet weak var clipActionsView: UIView!
    @IBOutlet weak var pauseView: UIView!

    let viewModel = ClipAdjustmentViewModel()
    weak var delegate: ClipAdjustmentViewControllerDelegate?

    private let player = AVPlayer()
    private lazy var playerLayer = AVPlayerLayer(player: player)
    private var isPlaying = false {
        didSet { updatePlayingState() }
    }

    private var timeObserver: Any?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPlayer()
        setupCollectionView()
        setupViewModel()
        setupGestureRecognizers()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isPlaying = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        adjustPlayerSize()
    }

    deinit {
        player.removeTimeObserver(timeObserver)
        timeObserver = nil
    }

    @IBAction func didTapCancel(_ sender: Any) {
        confirmCancelChanges {
            self.close()
        }
    }
    @IBAction func didTapDone(_ sender: Any) {
        viewModel.saveEdit()
    }
    @IBAction func didTapPlayToggle(_ sender: Any) {
        toggleClipPlay()
    }
    @IBAction func didTapEditClipCancel(_ sender: Any) {
        confirmCancelChanges {
            self.viewModel.cancelClipEdit()
        }
    }
    @IBAction func didTapEditClipConfirm(_ sender: Any) {
        viewModel.confirmClipEdit()
    }
    
    @IBAction func didTapDeleteClip(_ sender: Any) {
        confirmClipDelete()
    }
}

// MARK: - Configuration

extension ClipAdjustmentViewController {
    private func setupViewModel() {
        viewModel.$currentAssetParams.bind { [weak self] (params) in
            guard let self = self else {
                return
            }
            self.updateCurrentVideo(params: params)
            self.videoSlider.params = .init(assetParams: params, range: self.viewModel.minSeconds...self.viewModel.maxSeconds)
        }
        viewModel.$clips.bind { [weak self] (clips) in
            guard let self = self else {
                return
            }
            if clips.count == 0 {
                CreateStoryRouter(in: self.navigationController).returnToCreateStory()
                return
            }
            self.clipsCollectionView.reloadData()
        }
        viewModel.$saveResult.bind { [weak self] (result) in
            self?.handleSaveResult(result)
        }
        viewModel.$isSelectingMode.bind { [weak self] (isSelecting) in
            if isSelecting {
                self?.player.pause()
            } else if self?.isPlaying == true {
                self?.player.play()
            }
        }
        viewModel.$selectedFrame.bind { [weak self] (second) in
            guard let self = self else {
                return
            }
            self.player.seek(to: CMTime(seconds: second, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),toleranceBefore: .zero, toleranceAfter: .zero)
        }
        viewModel.$mode.bind { [weak self] (mode) in
            guard let self = self else {
                return
            }
            self.singleClipEditControlsView.isHidden = mode == .wholeClip
            self.clipsCollectionView.isHidden = mode == .singleClip
            self.clipActionsView.isHidden = mode == .wholeClip
        }
    }

    private func setupPlayer() {
        playerLayer.videoGravity = .resizeAspectFill
        videoContainerView.layer.addSublayer(playerLayer)
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time = CMTime(seconds: 0.01, preferredTimescale: timeScale)
        timeObserver = player.addPeriodicTimeObserver(forInterval: time, queue: .main) { [weak self] (time) in
            guard let self = self, self.player.rate != 0 else {
                return
            }
            if time.seconds >= self.viewModel.maxSeconds - 0.01 {
                self.player.pause()
                self.player.seek(to: CMTime(seconds: self.viewModel.minSeconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), toleranceBefore: .zero, toleranceAfter: .zero)
                self.player.play()
                return
            }
            self.videoSlider.frameTime = time
            var pastTime: Double = 0
            for (index, clip) in self.viewModel.clips.enumerated() {
                (self.clipsCollectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? AdjustmentClipCell)?
                    .isCurrentPlaying = time.seconds > pastTime && time.seconds < pastTime + clip.duration
                pastTime += clip.duration
            }
        }
    }

    private func setupCollectionView() {
        clipsCollectionView.register(R.nib.adjustmentClipCell)
        clipsCollectionView.register(R.nib.addMediaCell)
        clipsCollectionView.dragInteractionEnabled = true
        clipsCollectionView.reorderingCadence = .fast
    }

    private func adjustPlayerSize() {
        playerLayer.frame = videoContainerView.bounds
    }

    private func updatePlayingState() {
        isPlaying ? player.play() : player.pause()
        playButton.setImage(isPlaying ? R.image.stories_pause_small_icon() : R.image.stories_play_small_icon(), for: .normal)
        pauseView.isHidden = isPlaying
    }

    private func setupGestureRecognizers() {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleVideoTap))
        videoContainerView.addGestureRecognizer(tapRecognizer)
        videoContainerView.isUserInteractionEnabled = true
    }
}

// MARK: - Private methods

extension ClipAdjustmentViewController {
    private func close() {
        CreateStoryRouter(in: self.navigationController).popController()
    }

    private func toggleClipPlay() {
        isPlaying.toggle()
    }

    private func updateCurrentVideo(params: VideoAssetParams) {
        player.pause()
        let playerItem = AVPlayerItem(asset: params.asset)
        playerItem.videoComposition = params.videoComposition
        player.replaceCurrentItem(with: playerItem)
        if isPlaying {
            player.play()
        }
    }

    @objc func playerItemDidReachEnd(notification: Notification) {
        player.seek(to: .zero)
    }

    private func handleSaveResult(_ result: Result<Void, Error>?) {
        guard let result = result else {
            return
        }
        switch result {
        case .success:
            close()
            delegate?.adjustmentsComplete()
        case .failure(let error):
            self.handleError(error)
        }
    }

    private func confirmCancelChanges(completion: @escaping () -> Void) {
        Alert(title: nil, message: Alert.Message.cancelChanges)
            .configure(doneText: Alert.Action.ok)
            .configure(cancelText: Alert.Action.cancel)
            .show { (result) in
                if result == .done {
                    completion()
                }
            }
    }

    private func confirmClipDelete() {
        Alert(title: nil, message: Alert.Message.deleteClip)
            .configure(doneText: Alert.Action.ok)
            .configure(cancelText: Alert.Action.cancel)
            .show { (result) in
                if result == .done {
                    self.viewModel.removeSelectedClip()
                }
            }
    }

    @objc private func handleVideoTap() {
        isPlaying.toggle()
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout

extension ClipAdjustmentViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.clips.count + (viewModel.canAddMediaFromGallery ? 1 : 0)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == viewModel.clips.count {
            return collectionView.dequeueReusableCell(withReuseIdentifier: R.reuseIdentifier.addMediaCell, for: indexPath)!
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.reuseIdentifier.adjustmentClipCell, for: indexPath)!
        let clip = viewModel.clips[indexPath.row]
        cell.duration = clip.duration
        cell.thumbnail = FrameGenerator().single(from: .init(asset: clip.asset, videoComposition: clip.videoComposition, layerComposition: nil, audioMix: nil), at: 0)
        cell.isCurrentPlaying = indexPath.row == 0
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == viewModel.clips.count {
            GallerySelectorRouter(in: navigationController).openGallerySelection(delegate: viewModel)
            return
        }
        viewModel.selectClip(viewModel.clips[indexPath.row])
    }
}


extension ClipAdjustmentViewController: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let item = viewModel.clips[indexPath.row]
        let draggable = VideoEntityDraggable(entity: item)
        let dragItem = UIDragItem(itemProvider: .init(object: draggable))
        dragItem.localObject = item
        return [dragItem]
    }

    func collectionView(_ collectionView: UICollectionView, dragSessionWillBegin session: UIDragSession) {
        self.player.pause()
    }

    func collectionView(_ collectionView: UICollectionView, dragSessionDidEnd session: UIDragSession) {
        if isPlaying {
            self.player.play()
        }
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if collectionView.hasActiveDrag {
            return .init(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        return .init(operation: .forbidden)
    }

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath: IndexPath = {
            if let indexPath = coordinator.destinationIndexPath {
                return indexPath
            }
            let row = collectionView.numberOfItems(inSection: 0)
            return IndexPath(row: row - 1, section: 0)
        }()

        guard coordinator.proposal.operation == .move,
              let item = coordinator.items.first,
              let sourceIndexPath = item.sourceIndexPath else {
            return
        }
        clipsCollectionView.performBatchUpdates {
            viewModel.moveClip(from: sourceIndexPath.row, to: destinationIndexPath.row)
            clipsCollectionView.deleteItems(at: [sourceIndexPath])
            clipsCollectionView.insertItems(at: [destinationIndexPath])
        } completion: { (_) in
        }

    }


}

// MARK: - VideoEntityDraggable

class VideoEntityDraggable: NSObject, NSItemProviderWriting {
    static var writableTypeIdentifiersForItemProvider: [String] { ["videoEntity"] }

    func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        return nil
    }

    let entity: StoryCreator.VideoEntity

    init(entity: StoryCreator.VideoEntity) {
        self.entity = entity
        super.init()
    }
}
