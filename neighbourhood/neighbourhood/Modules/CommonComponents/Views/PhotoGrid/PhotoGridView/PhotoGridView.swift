//
//  PhotoGridView.swift
//  neighbourhood
//
//  Created by Artem Korzh on 07.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

// MARK: - Delegate protocol

protocol PhotoGridViewDelegate: class {
    func photoGridNewPhotoPressed()
    func photoGridRemovePressed(image: ImageModel)
    func photoGridImageSelected(image: ImageModel)
    func photoGridWillShowLastLine()
}

// MARK: - Defaults

private enum Defaults {
    static let numberOfImagesPerScreen: CGFloat = 3.0
    static let minimalSpacing: CGFloat = 5.0
}

// MARK: - PhotoGridView

class PhotoGridView: UIView {

    @IBOutlet private weak var collectionView: UICollectionView!

    private var fetchedImages: [ImageModel] = []
    private var temporaryImages: [URL: UIImage] = [:]

    private var totalCount: Int {
        fetchedImages.count + temporaryImages.count + (withAdd ? 1 : 0) + uploadingImagesCount
    }

    private var firstTemporaryIndex: Int {
        fetchedImages.count + (withAdd ? 1 : 0) - 1
    }

    private var uploadingImagesCount = 0
    
    public weak var delegate: PhotoGridViewDelegate?
    public var withAdd: Bool = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }

    // MARK: - Public functions

    public func setImages(_ images: [ImageModel]) {
        fetchedImages = images
        collectionView.reloadData()
    }

    public func addTemporaryImage(_ image: UIImage, for url: URL) {
        temporaryImages[url] = image
        let index = totalCount - 1
        collectionView.insertItems(at: [IndexPath(row: index, section: 0)])
    }

    public func replaceTemporayImage(for url: URL, with image: ImageModel) {
        fetchedImages.append(image)
        let index = firstTemporaryIndex
        if temporaryImages.keys.contains(url) {
            temporaryImages.removeValue(forKey: url)
            collectionView.reloadItems(at: [IndexPath(row: index, section: 0)])
        } else {
            collectionView.insertItems(at: [IndexPath(row: index, section: 0)])
        }
    }

    public func removeTemporaryImage(for url: URL) {
        if temporaryImages.keys.contains(url) {
            temporaryImages.removeValue(forKey: url)
            let index = totalCount
            collectionView.deleteItems(at: [IndexPath(row: index, section: 0)])
        }
    }
    
    public func imageUploadingStarted() {
        uploadingImagesCount += 1
        collectionView.insertItems(at: [IndexPath(item: withAdd ? 1 : 0, section: 0)])
    }
    
    public func imageUploadingFailed() {
        guard uploadingImagesCount > 0 else {
            return
        }
        uploadingImagesCount -= 1
        collectionView.deleteItems(at: [IndexPath(item: withAdd ? 1 : 0, section: 0)])
    }
    
    public func imageUploadingCompleted(with newImage: ImageModel) {
        guard uploadingImagesCount > 0 else {
            return
        }
        uploadingImagesCount -= 1
        fetchedImages.insert(newImage, at: 0)
        collectionView.reloadItems(at: [IndexPath(item: (withAdd ? 1 : 0) + uploadingImagesCount, section: 0)])
    }
}

// MARK: - UI supporting methods
private extension PhotoGridView {
    func initView() {
        loadFromXib(R.nib.photoGridView.name, contextOf: PhotoGridView.self)
        setupCollectionView()
    }

    func setupCollectionView() {
        collectionView.register(R.nib.photoGridAddCell)
        collectionView.register(R.nib.photoGridImageCell)
        collectionView.register(R.nib.photoGridLoadingCell)
    }
}

// MARK: - Supporting data methods
private extension PhotoGridView {
    func fetchedImage(for indexPath: IndexPath) -> ImageModel {
        withAdd ? fetchedImages[indexPath.row - 1 - uploadingImagesCount] : fetchedImages[indexPath.row - uploadingImagesCount]
    }
    
    func isIndexPathForAddCell(_ indexPath: IndexPath) -> Bool {
        withAdd && indexPath.row == 0
    }
    
    func isIndexPathForLoadingCell(_ indexPath: IndexPath) -> Bool {
        indexPath.row < fetchedImages.count - (withAdd ? 0 : 1)
    }
    
    func isIndexPathForImageCell(_ indexPath: IndexPath) -> Bool {
        let additionalItems = uploadingImagesCount + (withAdd ? 1 : 0)
        return indexPath.row < fetchedImages.count + additionalItems && indexPath.row > (additionalItems - 1)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout, UICollectionViewDataSource

extension PhotoGridView: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        totalCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if isIndexPathForImageCell(indexPath) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.nib.photoGridImageCell, for: indexPath)!
            cell.canBeRemoved = withAdd
            cell.delegate = self
            return cell
        }
        if isIndexPathForAddCell(indexPath) {
            return collectionView.dequeueReusableCell(withReuseIdentifier: R.nib.photoGridAddCell, for: indexPath)!
        }
        return collectionView.dequeueReusableCell(withReuseIdentifier: R.nib.photoGridLoadingCell, for: indexPath)!
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        if isIndexPathForAddCell(indexPath) {
            delegate?.photoGridNewPhotoPressed()
            return
        }
        if isIndexPathForImageCell(indexPath) {
            let image = fetchedImage(for: indexPath)
            delegate?.photoGridImageSelected(image: image)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let contentSize = collectionView.bounds
        let cellSize = (contentSize.width / Defaults.numberOfImagesPerScreen) - (Defaults.numberOfImagesPerScreen - 1) * Defaults.minimalSpacing
        return CGSize(width: cellSize, height: cellSize)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return Defaults.minimalSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if isIndexPathForImageCell(indexPath) {
            let image = fetchedImage(for: indexPath)
            let imageURL = image.formatted?.medium ?? image.origin
            (cell as? PhotoGridImageCell)?.imageURL = imageURL
        }
        if indexPath.item == totalCount - totalCount / Int(Defaults.numberOfImagesPerScreen) {
            delegate?.photoGridWillShowLastLine()
        }
    }
}

// MARK: - PhotoGridImageCellDelegate

extension PhotoGridView: PhotoGridImageCellDelegate {
    func photoGridImageRemovePressed(cell: PhotoGridImageCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else {
            return
        }
        let image = fetchedImage(for: indexPath)
        delegate?.photoGridRemovePressed(image: image)
    }
}
