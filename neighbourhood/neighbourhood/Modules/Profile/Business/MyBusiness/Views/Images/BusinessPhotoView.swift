//
//  BusinessPhotoView.swift
//  neighbourhood
//
//  Created by Dioksa on 04.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

protocol BusinessPhotoViewDelegate: class {
    func addNewBusinessImage()
    func removeBusinessImage(id: Int)
    func showFullScreenImage(_ image: ImageModel)
}

private let numberOfImagesPerScreen: CGFloat = 3.0
private let sideInset: CGFloat = 60.0
private let minimalSpacing: CGFloat = 5.0

final class BusinessPhotoView: UIView {
    @IBOutlet private weak var imagesCollectionView: UICollectionView!
//    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    weak var imageDelegate: BusinessPhotoViewDelegate?
    private var loadedImages = [ImageModel]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }
    
    private func initView() {
        loadFromXib(R.nib.businessPhotoView.name, contextOf: BusinessPhotoView.self)
        imagesCollectionView.register(R.nib.businessAddImageCell)
        imagesCollectionView.register(R.nib.businessCollectionViewImageCell)
        imagesCollectionView.register(R.nib.chatBackgroundLoadingCell)
        imagesCollectionView.dataSource = self
        imagesCollectionView.delegate = self
        configureCollectionViewSize()
    }
    
    private func configureCollectionViewSize() {
        let cellWidth = (UIScreen.main.bounds.width - 30) / 3
        let cellheight = cellWidth
        let cellSize = CGSize(width: cellWidth, height: cellheight)
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = cellSize
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        imagesCollectionView.setCollectionViewLayout(layout, animated: true)
        
        imagesCollectionView.reloadData()
    }
    
    public func saveNew(image: ImageModel?) {
        guard let image = image else { return }
        loadedImages.append(image)
        imagesCollectionView.insertItems(at: [IndexPath(row: loadedImages.count, section: 0)])
    }

    public func addTemporary(image: UIImage, url: URL) {
//        temporaryImages[url] = image
//        imagesCollectionView.insertItems(at: [IndexPath(row: loadedImages.count + temporaryImages.count, section: 0)])
    }

    public func removeTemporary(for url: URL?) {
//        if let url = url, temporaryImages.keys.contains(url) {
//            temporaryImages.removeValue(forKey: url)
//            imagesCollectionView.deleteItems(at: [IndexPath(row: loadedImages.count + 1, section: 0)])
//        }
    }
    
    public func showAllImages(images: [ImageModel]) {
        loadedImages = images
        imagesCollectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension BusinessPhotoView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return loadedImages.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if indexPath.row == 0 {
            return collectionView.dequeueReusableCell(withReuseIdentifier: R.nib.businessAddImageCell, for: indexPath)!
        }

        if indexPath.row <= loadedImages.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.nib.businessCollectionViewImageCell, for: indexPath)!
            cell.delegate = self

            if !loadedImages.isEmpty {
                cell.updateImage(with: loadedImages[indexPath.row - 1])
            }
            return cell
        }

        return collectionView.dequeueReusableCell(withReuseIdentifier: R.nib.chatBackgroundLoadingCell, for: indexPath)!
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            imageDelegate?.addNewBusinessImage()
        default:
            break
        }
    }
}

// MARK: - ImageCollectionUpdatableDelegate
extension BusinessPhotoView: ImageCollectionUpdatableDelegate {
    func openFullScreen(_ image: ImageModel) {
        imageDelegate?.showFullScreenImage(image)
    }
    
    func remove(image: ImageModel) {
        if let index = loadedImages.firstIndex(where: { $0.id == image.id }) {
            loadedImages.remove(at: index)
            imageDelegate?.removeBusinessImage(id: image.id)
            imagesCollectionView.deleteItems(at: [IndexPath(row: index + 1, section: 0)])
        }
    }
}
