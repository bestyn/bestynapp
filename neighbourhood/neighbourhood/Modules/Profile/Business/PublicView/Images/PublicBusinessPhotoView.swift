//
//  PublicBusinessPhotoView.swift
//  neighbourhood
//
//  Created by Dioksa on 04.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

protocol FullScreenImageLoadable: AnyObject {
    func openFullScreen(with image: UIImage)
    func openFullScreen(with imageURL: URL)
}

final class PublicBusinessPhotoView: UIView {
    @IBOutlet private weak var imagesCollectionView: UICollectionView!
    
    private var loadedImages = [ImageModel]()
    
    weak var imageDelegate: FullScreenImageLoadable?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }
    
    private func initView() {
        loadFromXib(R.nib.publicBusinessPhotoView.name, contextOf: PublicBusinessPhotoView.self)
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
    
    public func showAllImages(images: [ImageModel]) {
        loadedImages = images
        imagesCollectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension PublicBusinessPhotoView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return loadedImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.nib.businessCollectionViewImageCell, for: indexPath) else {
            NSLog("🔥 Error occurred while creating UICollectionViewCell")
            return UICollectionViewCell()
        }
        
        if !loadedImages.isEmpty {
            cell.hideRemoveButton()
            cell.updateImage(with: loadedImages[indexPath.row])
            cell.delegate = self
        }
        
        return cell
    }
}

// MARK: - ImageCollectionUpdatableDelegate
extension PublicBusinessPhotoView: ImageCollectionUpdatableDelegate {
    func remove(image: ImageModel) {}
    
    func openFullScreen(_ image: ImageModel) {
        imageDelegate?.openFullScreen(with: image.origin)
    }
}
