//
//  GallerySelectorViewController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 21.12.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import Photos

private enum Defaults {
    typealias Spacing = (horizontal: CGFloat, vertical: CGFloat)
    static let assetCollectionViewInsets: Spacing = (10, 0)
    static let selectedCollectionViewInsets: Spacing = (10, 0)
    static let assetCollectionViewSpacing: Spacing = (5,5)
    static let selectedCollectionViewSpacing: Spacing = (5,5)
}

class GallerySelectorViewController: BaseViewController {

    @IBOutlet weak var assetsCollectionView: UICollectionView!
    @IBOutlet weak var selectedCollectionView: UICollectionView!
    @IBOutlet weak var allButton: UIButton!
    @IBOutlet weak var imagesButton: UIButton!
    @IBOutlet weak var videosButton: UIButton!
    @IBOutlet var typeButtons: [UIButton]!

    let viewModel = GallerySelectorViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollections()
        setupFilterButtons()
        setupViewModel()
        viewModel.getAssets()
    }

    @IBAction func didTapCancel(_ sender: Any) {
        close()
    }
    @IBAction func didTapDone(_ sender: Any) {
        viewModel.doneSelection()
    }

    @IBAction func didTapAll(_ sender: Any) {
        viewModel.setSelectedType(.all)
    }

    @IBAction func didTapImages(_ sender: Any) {
        viewModel.setSelectedType(.photo)
    }

    @IBAction func didTapVideos(_ sender: Any) {
        viewModel.setSelectedType(.video)
    }
}

// MARK: - Configuration

extension GallerySelectorViewController {

    private func setupCollections() {
        selectedCollectionView.register(R.nib.gallerySelectedCell)
        assetsCollectionView.register(R.nib.galleryCell)
    }

    private func setupFilterButtons() {
        typeButtons.forEach { (button) in
            button.setBackgroundColor(color: R.color.greyBackground()!.withAlphaComponent(0.5), forState: .normal)
            button.setBackgroundColor(color: R.color.blueButton()!, forState: .disabled)
            button.setTitleColor(R.color.secondaryBlack(), for: .normal)
            button.setTitleColor(UIColor.white, for: .disabled)
        }
    }

    private func setupViewModel() {
        viewModel.$availableAssets.bind { [weak self] (_) in
            self?.assetsCollectionView.reloadData()
        }
        viewModel.$selectedAssets.bind { [weak self] (_) in
            self?.selectedCollectionView.reloadData()
        }
        viewModel.$mediaInICloud.bind { (isMediaInICloud) in
            DispatchQueue.main.async {
                if isMediaInICloud {
                    Toast.show(message: Alert.Message.iCloudSync)
                }
            }
        }
        viewModel.$selectedType.bind { [weak self] (type) in
            self?.typeButtons.forEach({$0.isEnabled = true})
            switch type {
            case .all:
                self?.allButton.isEnabled = false
            case .photo:
                self?.imagesButton.isEnabled = false
            case .video:
                self?.videosButton.isEnabled = false
            }
        }
        viewModel.$fetchingResult.bind { [weak self] (result) in
            guard let result = result else {
                return
            }
            switch result {
            case .success:
                self?.close()
            case .failure(let error):
                self?.handleError(error)
            }
        }
    }
}

extension GallerySelectorViewController {

    private func close() {
        dismiss(animated: true)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout, UICollectionViewDataSource

extension GallerySelectorViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case assetsCollectionView:
            return viewModel.availableAssets.count
        case selectedCollectionView:
            return viewModel.selectedAssets.count
        default:
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case assetsCollectionView:
            return assetCellFor(indexPath: indexPath)
        case selectedCollectionView:
            return selectedAssetCellFor(indexPath: indexPath)
        default:
            return UICollectionViewCell()
        }
    }

    private func assetCellFor(indexPath: IndexPath) -> UICollectionViewCell {
        let cell = assetsCollectionView.dequeueReusableCell(withReuseIdentifier: R.reuseIdentifier.galleryCell, for: indexPath)!
        cell.asset = viewModel.availableAssets[indexPath.row]
        return cell
    }

    private func selectedAssetCellFor(indexPath: IndexPath) -> UICollectionViewCell {
        let cell = selectedCollectionView.dequeueReusableCell(withReuseIdentifier: R.reuseIdentifier.gallerySelectedCell, for: indexPath)!
        cell.asset = viewModel.selectedAssets[indexPath.row]
        cell.delegate = self
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch collectionView {
        case assetsCollectionView:
            let width: CGFloat = (collectionView.bounds.width - Defaults.assetCollectionViewInsets.horizontal * CGFloat(2) - Defaults.assetCollectionViewSpacing.horizontal * CGFloat(2)) / CGFloat(3)
            return CGSize(width: width, height: width)
        case selectedCollectionView:
            return CGSize(width: 48, height: 48)
        default:
            return .zero
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        switch collectionView {
        case assetsCollectionView:
            return Defaults.assetCollectionViewSpacing.horizontal
        case selectedCollectionView:
            return Defaults.selectedCollectionViewSpacing.horizontal
        default:
            return 0
        }
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        switch collectionView {
        case assetsCollectionView:
            return Defaults.assetCollectionViewSpacing.vertical
        case selectedCollectionView:
            return Defaults.selectedCollectionViewSpacing.vertical
        default:
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        switch collectionView {
        case assetsCollectionView:
            return .init(
                top: Defaults.assetCollectionViewInsets.vertical,
                left: Defaults.assetCollectionViewInsets.horizontal,
                bottom: Defaults.assetCollectionViewInsets.vertical,
                right: Defaults.assetCollectionViewInsets.horizontal)
        case selectedCollectionView:
            return .init(
                top: Defaults.selectedCollectionViewInsets.vertical,
                left: Defaults.selectedCollectionViewInsets.horizontal,
                bottom: Defaults.selectedCollectionViewInsets.vertical,
                right: Defaults.selectedCollectionViewInsets.horizontal)
        default:
            return .zero
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard collectionView == assetsCollectionView else {
            return
        }
        let asset = viewModel.availableAssets[indexPath.row].asset
        viewModel.toggleAssetSelection(asset: asset)
    }

}

// MARK: - GallerySelectedCellDelegate

extension GallerySelectorViewController: GallerySelectedCellDelegate {
    func selectedAssetRemoved(_ asset: PHAsset) {
        viewModel.toggleAssetSelection(asset: asset)
    }
}
