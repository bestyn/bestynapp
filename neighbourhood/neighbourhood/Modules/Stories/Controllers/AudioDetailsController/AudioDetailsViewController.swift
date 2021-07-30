//
//  AudioDetailsViewController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 15.02.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import UIKit

private enum Defaults {
    static let collectionViewInsets: (horizontal: CGFloat, vertical: CGFloat) = (10, 15)
    static let collectionViewSpacing: CGFloat = 6
    static let imagesPerRow: CGFloat = 3
    static let topViewCornerRadius: CGFloat = 16
}

class AudioDetailsViewController: BaseViewController {

    @IBOutlet weak var audioTrackView: AudioTrackView!
    @IBOutlet weak var storiesCollectionView: UICollectionView!
    @IBOutlet weak var topView: UIView!
    @IBOutlet var emptyView: UIView!

    private let viewModel: AudioDetailsViewModel 

    init(audioTrack: AudioTrackModel) {
        self.viewModel = .init(audioTrack: audioTrack)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AudioPlayerService.shared.stop()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTopView()
        setupCollectionView()
        setupAudioTrackView()
        setupEmptyView()
        setupViewModel()
    }
    @IBAction func didTapBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Configuration

extension AudioDetailsViewController {

    private func setupTopView() {
        topView.roundCorners(corners: [.bottomLeft, .bottomRight], radius: Defaults.topViewCornerRadius)
    }

    private func setupCollectionView() {
        storiesCollectionView.register(R.nib.photoGridImageCell)
    }

    private func setupAudioTrackView() {
        audioTrackView.delegate = self
    }

    private func setupEmptyView() {
        emptyView.frame = CGRect(x: 16, y: storiesCollectionView.contentOffset.y + 4, width: view.frame.width - 32, height: 80)
        storiesCollectionView.backgroundView = emptyView
    }

    private func setupViewModel() {
        viewModel.$audioTrack.bind { [weak self] (audioTrack) in
            self?.audioTrackView.audioTrack = audioTrack
        }
        viewModel.$stories.bind { [weak self] (_) in
            self?.updateEmptyState()
            self?.storiesCollectionView.reloadData()
        }
        viewModel.$isFetching.bind { [weak self] (isFetching) in
            self?.updateEmptyState()
            guard self?.viewModel.stories.count == 0, isFetching else {
                return
            }
            print(isFetching)
        }
        viewModel.$lastError.bind { [weak self] (error) in
            guard let error = error else {
                return
            }
            self?.handleError(error)
        }
    }
}

// MARK: - Private methods

extension AudioDetailsViewController {
    private func updateEmptyState() {
        emptyView.isHidden = viewModel.isFetching || viewModel.stories.count > 0
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout

extension AudioDetailsViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.stories.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == viewModel.stories.count - 1 {
            viewModel.fetchMoreStories()
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.reuseIdentifier.photoGridImageCell, for: indexPath)!
        cell.imageURL = viewModel.stories[indexPath.row].story.media?.first?.formatted?.thumbnail
        cell.canBeRemoved = false
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(
            top: Defaults.collectionViewInsets.vertical,
            left: Defaults.collectionViewInsets.horizontal,
            bottom: Defaults.collectionViewInsets.vertical,
            right: Defaults.collectionViewInsets.horizontal)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellSize = (collectionView.bounds.width - Defaults.collectionViewInsets.horizontal * 2 - Defaults.collectionViewSpacing * 2) / Defaults.imagesPerRow
        return .init(width: cellSize, height: cellSize)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return Defaults.collectionViewSpacing
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return Defaults.collectionViewSpacing
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let story = viewModel.stories[indexPath.row]
        StoriesRouter(in: navigationController).openAudioStoriesList(audio: viewModel.audioTrack, anchorStory: story.story)
    }
}

// MARK: - AudioTrackViewDelegate

extension AudioDetailsViewController: AudioTrackViewDelegate {
    func trackFavoriteToggled(track: AudioTrackModel) {
        viewModel.toggleTrackFavorite()
    }

    func trackMorePressed(track: AudioTrackModel) {
        let controller = EntityMenuController(entity: track)
        controller.onMenuSelected = { [weak self] (type, track) in
            guard let self = self else {
                return
            }
            switch type {
            case .report:
                BasicProfileRouter(in: self.navigationController).openReportViewController(for: track)
            default:
                break
            }
        }
        present(controller.alertController, animated: true)
    }
}
