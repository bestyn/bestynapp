//
//  NewsHeaderView.swift
//  neighbourhood
//
//  Created by Andrii Zakhliupanyi on 11.08.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

protocol NewsHeaderViewDelegate: class {
    func newsHeaderViewDidLoadMore()
}

class NewsHeaderView: UITableViewHeaderFooterView {
    static let reuseIdentifier: String = String(describing: self)

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    weak var delegate: NewsHeaderViewDelegate?
    
    var items: [NewsModel] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    static let height: CGFloat = NewsHeaderCollectionCell.size().height + 65 // 65 - height top view in cell
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    private func setup() {
        titleLabel.text = R.string.localizable.titleNewsFeed()
        collectionView.register(R.nib.newsHeaderCollectionCell)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.reloadData()
    }
}

extension NewsHeaderView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.reuseIdentifier.newsHeaderCollectionCell, for: indexPath)!
        let model = items[indexPath.row]
        cell.imageView.image = nil
        
        if let imageURL = model.image,
            UIApplication.shared.canOpenURL(imageURL) {
            var comps = URLComponents(url: imageURL, resolvingAgainstBaseURL: false)
            comps?.scheme = "https"
            let httpsURL = comps?.url
            
            cell.imageView.kf.setImage(with: httpsURL) { result in
                switch result {
                case .failure(_):
                    self.setDefaultImage(cell)
                default:
                    break
                }
            }
        } else {
            setDefaultImage(cell)
        }
        cell.descriptionLabel.text = model.description
        return cell
    }
    
    private func setDefaultImage(_ cell: NewsHeaderCollectionCell) {
        let randomImage = Int.random(in: 1..<4)
        cell.imageView.image = UIImage(named: "news_empty_\(randomImage)")
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if items.count <= indexPath.row + 1 {
            delegate?.newsHeaderViewDidLoadMore()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        NewsHeaderCollectionCell.size()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let url = items[indexPath.row].url else {
            return
        }
        AnalyticsService.logNewsClicked()
        UIApplication.shared.open(url)
    }
}
