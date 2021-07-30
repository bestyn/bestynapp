//
//  ChatBackgroundViewController.swift
//  neighbourhood
//
//  Created by Dioksa on 24.06.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

final class ChatBackgroundViewController: BaseViewController {
    @IBOutlet private weak var imagesCollectionView: UICollectionView!
    
    private var imageNames: [String] = [R.image.chat_background_default.name]
    private var allImages: [String: UIImage] = [R.image.chat_background_default.name: R.image.chat_background_default()!]
    private let downloadedImages = [
        R.image.img1.name,
        R.image.img2.name,
        R.image.img3.name,
        R.image.img4.name,
        R.image.img6.name,
        R.image.img7.name,
        R.image.img8.name,
        R.image.img9.name,
        R.image.img10.name,
        R.image.img11.name,
        R.image.img12.name,
        R.image.img13.name,
        R.image.img14.name,
        R.image.img15.name,
        R.image.img16.name
    ]
    private var imagesFetched = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagesCollectionView.register(R.nib.chatBackgroundCell)
        imagesCollectionView.register(R.nib.chatBackgroundLoadingCell)
        configureCollectionViewSize()
        imagesCollectionView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        OnDemandRecourcesServices.shared.preloadResources(tag: "chatBackground") { [weak self] (error) in
            if let error = error {
                DispatchQueue.main.async {
                    Toast.show(message: error.localizedDescription)
                }
                return
            }
            guard let self = self else {
                return
            }
            self.imagesFetched = true
            self.downloadedImages.forEach { (name) in
                if let image = UIImage(named: name) {
                    self.allImages[name] = image
                    self.imageNames.append(name)
                }
            }
            DispatchQueue.main.async {
                self.imagesCollectionView.reloadData()
            }
        }
    }
    
    private func configureCollectionViewSize() {
        let cellWidth = (UIScreen.main.bounds.width) / 2
        let cellheight = (UIScreen.main.bounds.width) / 1.6
        let cellSize = CGSize(width: cellWidth, height: cellheight)

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = cellSize
        layout.minimumInteritemSpacing = .zero
        layout.minimumLineSpacing = .zero
        imagesCollectionView.setCollectionViewLayout(layout, animated: true)

        imagesCollectionView.reloadData()
    }
    
    // MARK: - Private actions
    @IBAction func backButtonDidTap(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension ChatBackgroundViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imagesFetched ? imageNames.count : imageNames.count + downloadedImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row >= imageNames.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.nib.chatBackgroundLoadingCell, for: indexPath)!
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.nib.chatBackgroundCell, for: indexPath)!
        let imageName = imageNames[indexPath.row]
        cell.setImage(allImages[imageName]!, isDefault: indexPath.row == 0)
        if ArchiveService.shared.image == nil, imageName == R.image.chat_background_default.name {
            cell.isSelected = true
        } else {
            cell.isSelected = imageName == ArchiveService.shared.image
        }
                
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.visibleCells.forEach {
            ($0 as? ChatBackgroundCell)?.isSelected = false
        }
        
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.isSelected = true
        let imageName = imageNames[indexPath.row]
        ArchiveService.shared.image = imageName
        if imageName != R.image.chat_background_default.name,
           let image = allImages[imageName] {
            DispatchQueue.global().async {
                UIImage.saveChatBackground(image: image)
            }
        }
        Toast.show(message: Alert.Message.chatBackroungChanged)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.isSelected = false
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return indexPath.row < imageNames.count
    }
}
