//
//  ImageViewLoader.swift
//  neighbourhood
//
//  Created by Dioksa on 27.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

final class ImageViewLoader {
    public func loadImage(from url: URL, completion: @escaping (UIImage) -> ()) {
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print(error)
                return
            }

            guard let mimeType = response?.mimeType,
                mimeType.hasPrefix("image"),
                let data = data,
                let image = UIImage(data: data) else {
                    return
            }

            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
}
