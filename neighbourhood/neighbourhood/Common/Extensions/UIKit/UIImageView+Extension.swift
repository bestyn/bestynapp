//
//  UIImageView+Extension.swift
//  neighbourhood
//
//  Created by Artem Korzh on 08.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
extension UIImageView {
    func load(from url: URL, withLoader: Bool = false, completion: @escaping () -> ()) {
        
        var loaderIndicator: UIActivityIndicatorView?
        if withLoader {
            let loader = UIActivityIndicatorView()
            loader.color = R.color.accentGreen()
            if #available(iOS 13.0, *) {
                loader.style = .medium
            }
            loader.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(loader)
            loader.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            loader.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            loader.startAnimating()
            loaderIndicator = loader
        }
        DispatchQueue.global(qos: .userInitiated).async {
            UIImage.load(from: url) { (image) in
                DispatchQueue.main.async {
                    if withLoader {
                        loaderIndicator?.removeFromSuperview()
                    }
                    if let image = image {
                        self.image = image
                        completion()
                    }
                }
            }
        }
    }
}
