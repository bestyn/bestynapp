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
}

final class BusinessPhotoView: UIView {
    @IBOutlet private weak var imagesCollectionView: UICollectionView!
    
    weak var imageDelegate: BusinessPhotoViewDelegate?
    private var loadedImages = [UserAvatar]()
    
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
        imagesCollectionView.dataSource = self
        imagesCollectionView.delegate = self
        
        let cellWidth : CGFloat = (imagesCollectionView.frame.size.width - 60) / 3.0
        let cellheight : CGFloat = cellWidth
        let cellSize = CGSize(width: cellWidth , height:cellheight)
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = cellSize
        layout.minimumLineSpacing = 5.0
        layout.minimumInteritemSpacing = 5.0
        imagesCollectionView.setCollectionViewLayout(layout, animated: true)
        
        imagesCollectionView.reloadData()
    }
    
    public func saveNew(image: UserAvatar?) {
        guard let image = image else { return }
        loadedImages.append(image)
        imagesCollectionView.insertItems(at: [IndexPath(row: loadedImages.count, section: 0)])
    }
    
    public func showAllImages(images: [UserAvatar]) {
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
        var cell: UICollectionViewCell?
        
        switch indexPath.row {
        case 0:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.nib.businessAddImageCell, for: indexPath)
        default:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.nib.businessCollectionViewImageCell, for: indexPath)
            (cell as? BusinessCollectionViewImageCell)?.delegate = self
            
            if !loadedImages.isEmpty {
                (cell as? BusinessCollectionViewImageCell)?.updateImage(with: loadedImages[indexPath.row - 1])
            }
        }
        
        guard let collectionCell = cell else {
            assertionFailure("🔥 Error occurred while creating UICollectionViewCell")
            return UICollectionViewCell()
        }
        
        return collectionCell
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
    func remove(image: UserAvatar) {
        if let index = loadedImages.firstIndex(where: { $0.id == image.id }) {
            loadedImages.remove(at: index)
            imageDelegate?.removeBusinessImage(id: image.id)
            imagesCollectionView.deleteItems(at: [IndexPath(row: index + 1, section: 0)])
        }
    }
}
