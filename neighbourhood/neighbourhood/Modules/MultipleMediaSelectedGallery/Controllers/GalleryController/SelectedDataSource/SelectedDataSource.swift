//
//  SelectedDataSource.swift
//  neighbourhood
//
//  Created by iphonovv on 30.11.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import Photos

class SelectedDataSource: NSObject, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var models: [GallerySelectedModel] = []
    
    let sectionInsets = UIEdgeInsets(top: 50.0,
                                     left: 10.0,
                                     bottom: 50.0,
                                     right: 10.0)
    let itemsPerRow = 5
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.models.count < 5 ? self.models.count : 5
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let model = models[indexPath.item]
        
        
        
        let sideSize = (collectionView.bounds.width - 16) / 3
        
        guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: R.nib.selectedCollectionViewCell.identifier,
                for: indexPath) as? GallerySelectedCell else {
            return UICollectionViewCell()
        }
        
        PHImageManager.default().requestImage(
            for: model.asset,
            targetSize: CGSize(width: sideSize, height: sideSize),
            contentMode: .aspectFill, options: nil) { (image: UIImage?, _) -> Void in
            cell.fill(model: .init(image: image))
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        //2
        let paddingSpace = sectionInsets.left * CGFloat(itemsPerRow + 1)
        let availableWidth = collectionView.frame.width - (paddingSpace + 10)
        let widthPerItem = availableWidth / CGFloat(itemsPerRow)
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
}
