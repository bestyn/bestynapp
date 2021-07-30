//
//  UIImage+Extension.swift
//  neighbourhood
//
//  Created by Artem Korzh on 12.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

private var cache: [URL: UIImage] = [:]

extension UIImage {
    func crop(rect: CGRect) -> UIImage? {
        guard let cgimage = self.cgImage else {
            return nil
        }

        let cropRect = CGRect(x: rect.origin.x * self.scale,
                              y: rect.origin.y * self.scale,
                              width: rect.width * self.scale,
                              height: rect.height * self.scale)
        guard let imageRef: CGImage = cgimage.cropping(to: cropRect) else {
            return nil
        }

        return UIImage(cgImage: imageRef, scale: self.scale, orientation: .up)
    }

    static func colored(size: CGSize, filledWithColor color: UIColor = UIColor.clear) -> UIImage? {
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: size)

        UIGraphicsBeginImageContext(size)
        color.set()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }

    func resized(percentage: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: size.width * percentage, height: size.height * percentage)
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    func compress(maxSizeMB: Int) -> UIImage? {
        guard let imageData = jpegData(compressionQuality: 1) else { return nil }

        let KBinMB: Double = 1024
        var resizingImage = self
        var imageSizeKB = Double(imageData.count) / KBinMB
        let maxSizeKB = Double(maxSizeMB) * KBinMB

        while imageSizeKB > maxSizeKB {
            guard let resizedImage = resizingImage.resized(percentage: 0.9),
                let imageData = resizedImage.jpegData(compressionQuality: 1)
                else { return nil }

            resizingImage = resizedImage
            imageSizeKB = Double(imageData.count) / KBinMB
        }

        return resizingImage
    }

    func rotate(radians: CGFloat) -> UIImage {
        let rotatedSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: CGFloat(radians)))
            .integral.size
        UIGraphicsBeginImageContext(rotatedSize)
        if let context = UIGraphicsGetCurrentContext() {
            let origin = CGPoint(x: rotatedSize.width / 2.0,
                                 y: rotatedSize.height / 2.0)
            context.translateBy(x: origin.x, y: origin.y)
            context.rotate(by: radians)
            draw(in: CGRect(x: -origin.y, y: -origin.x,
                            width: size.width, height: size.height))
            let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            return rotatedImage ?? self
        }

        return self
    }

    static func load(from url: URL, completion: @escaping (UIImage?) -> Void) {
        if let image = cache[url] {
            DispatchQueue.main.async {
                completion(image)
            }
            return
        }

        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print(error)
                completion(nil)
                return
            }

            guard let mimeType = response?.mimeType,
                mimeType.hasPrefix("image"),
                let data = data,
                let image = UIImage(data: data) else {
                completion(nil)
                    return
            }

            cache[url] = image
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
}


extension UIImage {
    private static var chatBackgroundImageURL: URL? {
        guard let appFolderURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let imageURL = appFolderURL.appendingPathComponent("chatBackgroundImage").appendingPathExtension("jpg")
        return imageURL
    }

    static var chatBackground: UIImage? {
        guard let path = chatBackgroundImageURL?.path,
              FileManager.default.fileExists(atPath: path),
              let image = UIImage(contentsOfFile: path) else {
            return nil
        }
        return image
    }

    static func saveChatBackground(image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 1) ?? image.pngData() else {
            return
        }
        guard let imageURL = chatBackgroundImageURL else {
            return
        }
        do {
            try data.write(to: imageURL, options: .atomic)
        } catch {
            print(error.localizedDescription)
        }
    }

    func fixOrientation() -> UIImage {
        let imageView = UIImageView(image: self)
        return imageView.screenshot ?? self
    }
}
