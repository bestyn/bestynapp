//
//  GallerySelectorViewModel.swift
//  neighbourhood
//
//  Created by Artem Korzh on 21.12.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import Photos
import UIKit
import AVFoundation

struct GallerySelectionAsset {
    enum LoadingState {
        case idle
        case loading
        case loaded
        case loadFailed
    }

    let asset: PHAsset
    var selectedIndex: Int?
    var loadingState: LoadingState = .idle
}

enum GallerySelectionEntity {
    case image(UIImage)
    case video(AVAsset)
}

enum GallerySelectorMediaType {
    case image
    case video
}

protocol GallerySelectorDelegate: class {
    func mediaSelected(entities: [GallerySelectionEntity])
    func canSelectMore(mediaType: GallerySelectorMediaType, imagesSelected: Int, videosSelected: Int) -> Bool
}

class GallerySelectorViewModel {

    @Observable private(set) var availableAssets: [GallerySelectionAsset] = []
    @Observable private(set) var selectedAssets: [PHAsset] = []
    @Observable private(set) var selectedType: GalleryAssetType = .all
    @Observable private(set) var isFetchingMedia: Bool = false
    @SingleEventObservable private(set) var fetchingResult: Result<Void, Error>?
    @ObservableState private(set) var mediaInICloud = false

    public weak var delegate: GallerySelectorDelegate?
    public func canSelectMore(assetMediaType: PHAssetMediaType) -> Bool {
        let imagesCount = selectedAssets.filter({$0.mediaType == .image}).count
        let videosCount = selectedAssets.filter({$0.mediaType == .video}).count
        let mediaType: GallerySelectorMediaType
        switch assetMediaType {
        case .image:
            mediaType = .image
        case .video:
            mediaType = .video
        default:
            return false
        }
        return delegate?.canSelectMore(mediaType: mediaType, imagesSelected: imagesCount, videosSelected: videosCount) ?? true
    }

    public func getAssets() {
        fetchAssets(type: selectedType)
    }

    public func setSelectedType(_ type: GalleryAssetType) {
        selectedType = type
        fetchAssets(type: type)
    }

    public func toggleAssetSelection(asset: PHAsset) {
        if selectedAssets.contains(asset) {
            selectedAssets.removeAll(where: {$0 == asset})
        } else if canSelectMore(assetMediaType: asset.mediaType) {
            selectedAssets.append(asset)
        }
        availableAssets = availableAssets.map({ (selectionAssets) -> GallerySelectionAsset in
            if let index = selectedAssets.firstIndex(of: selectionAssets.asset) {
                return GallerySelectionAsset(asset: selectionAssets.asset, selectedIndex: index)
            }
            return GallerySelectionAsset(asset: selectionAssets.asset, selectedIndex: nil)
        })
    }

    public func doneSelection() {
        guard selectedAssets.count > 0 else {
            Toast.show(message: Alert.Message.noMediaSelected)
            return
        }
        mediaInICloud = false
        var selectedEntities: [(GallerySelectionEntity, Int)] = []
        let fetchGroup = DispatchGroup()
        selectedAssets.enumerated().forEach { (index, asset) in

            updateLoadingState(asset: asset, state: .loading)
            fetchGroup.enter()
            let orderIndex = index
            if asset.mediaType == .image {
                fetchImage(asset: asset) { [weak self] (image) in
                    if let image = image {
                        selectedEntities.append((.image(image), orderIndex))
                        self?.updateLoadingState(asset: asset, state: .loaded)
                    } else {
                        self?.updateLoadingState(asset: asset, state: .loadFailed)
                    }
                    fetchGroup.leave()
                }
            } else {
                fetchVideo(asset: asset) { [weak self] (avAsset) in
                    if let avAsset = avAsset {
                        selectedEntities.append((.video(avAsset), orderIndex))
                        self?.updateLoadingState(asset: asset, state: .loaded)
                    } else {
                        self?.updateLoadingState(asset: asset, state: .loadFailed)
                    }
                    fetchGroup.leave()
                }
            }
        }

        fetchGroup.notify(queue: .main) {
            self.isFetchingMedia = false
            self.delegate?.mediaSelected(entities: selectedEntities.sorted(by: {$0.1 < $1.1}).map({$0.0}))
            self.fetchingResult = .success(())
        }
    }

    private func fetchImage(asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let imageOptions = PHImageRequestOptions()
        imageOptions.resizeMode = .exact
        imageOptions.deliveryMode = .highQualityFormat
        imageOptions.isNetworkAccessAllowed = true
        imageOptions.progressHandler = { [weak self] (_, _, _, _) in self?.mediaInICloud = true }
        let screen = UIScreen.main
        var width = screen.bounds.size.width * screen.scale
        let offset = fmod(width, 16)
        width = width + 16 - offset
        let height = width * screen.bounds.size.height / screen.bounds.size.width
        let size = CGSize(width: width, height: height)

        PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFit, options: imageOptions) { (image, _) in
            guard let image = image else {
                completion(nil)
                return
            }
            completion(image)
        }
    }

    private func fetchVideo(asset: PHAsset, completion: @escaping (AVAsset?) -> Void) {
        let videoOptions = PHVideoRequestOptions()
        videoOptions.deliveryMode = .highQualityFormat
        videoOptions.isNetworkAccessAllowed = true
        videoOptions.progressHandler = { [weak self] (_, _, _, _) in self?.mediaInICloud = true }
        PHImageManager.default().requestAVAsset(forVideo: asset, options: videoOptions) { (avAsset, _, info) in
            guard let avAsset = avAsset else {
                completion(nil)
                return
            }
            completion(avAsset)
        }
    }

    private func updateLoadingState(asset: PHAsset, state: GallerySelectionAsset.LoadingState) {
        DispatchQueue.main.async {
            self.availableAssets = self.availableAssets.map({ (selectionAsset) -> GallerySelectionAsset in
                if selectionAsset.asset == asset {
                    var selectionAsset = selectionAsset
                    selectionAsset.loadingState = state
                    return selectionAsset
                }
                return selectionAsset
            })
        }
    }

    private func updateProgress(for asset: PHAsset, progress: Double) {
        availableAssets = availableAssets.map({ (selectionAsset) -> GallerySelectionAsset in
            if selectionAsset.asset == asset {
                var selectionAsset = selectionAsset
//                selectionAsset.progress = progress
                return selectionAsset
            }
            return selectionAsset
        })
    }
}

extension GallerySelectorViewModel {

    private func fetchAssets(type: GalleryAssetType) {
        let assets = GalleryService().fetchAssets(type: type)
        var selectionAssets = [GallerySelectionAsset]()
        for index in 0..<assets.count {
            let asset = assets.object(at: index)
            if let index = selectedAssets.firstIndex(of: asset) {
                selectionAssets.append(.init(asset: asset, selectedIndex: index))
                continue
            }
            selectionAssets.append(.init(asset: asset, selectedIndex: nil))
        }
        availableAssets = selectionAssets
    }
}
