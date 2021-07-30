//
//  GalleryControllerViewController.swift
//  neighbourhood
//
//  Created by iphonovv on 27.11.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import Photos



class GalleryControllerViewController: BaseViewController {
    
    @IBOutlet var cancelButton: UIButton?
    @IBOutlet var doneButton: UIButton?
    @IBOutlet var dropDownButton: UIButton?
    
    @IBOutlet var allButton: UIButton!
    @IBOutlet var imagesButton: UIButton!
    @IBOutlet var videoButton: UIButton!
    
    @IBOutlet var collectionView: UICollectionView?
    @IBOutlet var selectedCollectionView: UICollectionView?
    
    var galleryDataSource: GalleryDataSource = .init()
    var selectedDataSource: SelectedDataSource = .init()
    
    var assets: [PHAsset] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.prepareCollection()
        self.prepareSelectedCollection()
        self.bind()
        self.fetchAll()
        
        self.allButton.addTarget(self, action: #selector(self.fetchAll), for: .touchUpInside)
        self.imagesButton.addTarget(self, action: #selector(self.fetchPhoto), for: .touchUpInside)
        self.videoButton.addTarget(self, action: #selector(self.fetchVideo), for: .touchUpInside)
    }
    
    @objc private func fetchAll() {
        self.fetch(type: .all)
    }
    
    @objc private func fetchPhoto() {
        self.fetch(type: .photo)
    }
    
    @objc private func fetchVideo() {
        self.fetch(type: .video)
    }
    
    private func fetch(type: AssetType) {
        self.galleryDataSource.selected = []
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            reloadAssets(type: type)
        } else {
            PHPhotoLibrary.requestAuthorization({ (status: PHAuthorizationStatus) -> Void in
                if status == .authorized {
                    self.reloadAssets(type: type)
                } else {
                    self.showNeedAccessMessage()
                }
            })
        }
    }
    
    private func bind() {
        self.galleryDataSource.$selected.bind(l: { [weak self] models in
            self?.selectedDataSource.models = models
            self?.selectedCollectionView?.reloadData()
        })
    }
    
    private func reloadAssets(type: AssetType) {
        let assets: PHFetchResult<PHAsset>
        switch type {
        case .all:
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate",ascending: false)]
            fetchOptions.predicate = NSPredicate(format: "mediaType = %d || mediaType = %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
            assets = PHAsset.fetchAssets(with: fetchOptions)
        case .photo:
            assets = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: nil)
        case .video:
            assets = PHAsset.fetchAssets(with: PHAssetMediaType.video, options: nil)
        }

        self.galleryDataSource.models = assets
        self.collectionView?.reloadData()
    }
    
    private func showNeedAccessMessage() {
        let alert = UIAlertController(title: "Image picker", message: "App need get access to photos", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction) -> Void in
            self.dismiss(animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction) -> Void in
            UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString)!)
        }))
        
        show(alert, sender: nil)
    }
    
    private func prepareCollection() {        
        let datasource = self.galleryDataSource
        let collection = self.collectionView
        collection?.dataSource = datasource
        collection?.delegate = datasource
        collection?.register(R.nib.galleryCollectionViewCell)
        collection?.allowsMultipleSelection = true
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = .init(top: 15, left: 10, bottom: 0, right: 10)
        collection?.collectionViewLayout = layout
    }
    
    private func prepareSelectedCollection() {
        let datasource = self.selectedDataSource
        let collection = self.selectedCollectionView
        collection?.dataSource = datasource
        collection?.delegate = datasource
        collection?.register(R.nib.selectedCollectionViewCell)
        collection?.allowsSelection = false
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = .init(top: 0, left: 10, bottom: 0, right: 10)
        collection?.collectionViewLayout = layout
    }
}
