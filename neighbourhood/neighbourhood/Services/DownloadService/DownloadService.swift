//
//  DownloadService.swift
//  neighbourhood
//
//  Created by Artem Korzh on 26.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import Photos

struct DownloadService {

    private static var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.color = R.color.blueButton()
        activityIndicator.startAnimating()
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()

    static func saveImageToGallery(image: UIImage) {
        performGalleryOperation {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }

    static func saveImageToGallery(imageURL: URL) {
        performGalleryOperation {
            PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: imageURL)
        }
    }

    static func saveAudioToFiles(audioURL: URL) {
        guard let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let finalPath = documentsDirectoryURL.appendingPathComponent(audioURL.lastPathComponent)
        if FileManager.default.fileExists(atPath: finalPath.path) {
            Toast.show(message: "Media file has been already saved to your device")
            return
        }
        showIndicator()
        URLSession.shared.downloadTask(with: audioURL) { (location, response, error) in
            if let error = error {
                Toast.show(message: error.localizedDescription)
                return
            }
            guard let location = location else {
                return
            }
            do {
                try FileManager.default.moveItem(at: location, to: finalPath)
                DispatchQueue.main.async {
                    Toast.show(message: R.string.localizable.mediaSaved())
                }
            } catch { Toast.show(message: error.localizedDescription) }
        }.resume()
    }

    static func saveVideoToGallery(videoURL: URL) {
        guard let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let finalPath = documentsDirectoryURL.appendingPathComponent(videoURL.lastPathComponent)
        if FileManager.default.fileExists(atPath: finalPath.path) {
            Toast.show(message: "Media file has been already saved to your device")
            return
        }
        showIndicator()
        URLSession.shared.downloadTask(with: videoURL) { (location, response, error) in
            if let error = error {
                Toast.show(message: error.localizedDescription)
                return
            }
            guard let location = location else {
                return
            }
            do {
                try FileManager.default.moveItem(at: location, to: finalPath)
                Self.performGalleryOperation {
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: finalPath)
                }
            } catch { Toast.show(message: error.localizedDescription) }
        }.resume()
    }

    private static func performGalleryOperation(changes: @escaping () -> Void) {
        let save = {
            DispatchQueue.main.async {
                Self.showIndicator()
                PHPhotoLibrary.shared().performChanges(changes) { (saved, error) in
                    DispatchQueue.main.async {
                        Self.hideIndicator()
                        if let error = error {
                            Toast.show(message: error.localizedDescription)
                            return
                        }
                        if saved {
                            Toast.show(message: "Media file was successfully saved to your device")
                        }
                    }
                }
            }
        }
        let statusCheck = { (status: PHAuthorizationStatus) in
            let positiveStatuses: [PHAuthorizationStatus]
            if #available(iOS 14, *) {
                positiveStatuses = [.authorized, .limited]
            } else {
                positiveStatuses = [.authorized]
            }
            if positiveStatuses.contains(status) {
                save()
                return
            }
            Alert(title: Alert.Title.photoLibraryPermission, message: Alert.Message.photoLibraryPermission)
                .configure(cancelText: Alert.Action.cancel)
                .configure(doneText: Alert.Action.settings)
                .show { (status) in
                    if status == .done {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    }
                }
        }
        if #available(iOS 14, *) {
            PHPhotoLibrary.requestAuthorization(for: .addOnly, handler: statusCheck)
        } else {
            PHPhotoLibrary.requestAuthorization(statusCheck)
        }
    }


    private static func showIndicator() {
        guard let presentedViewController = UIApplication.shared.currentWindow?.rootViewController?.presentedViewController else {
            return
        }
        guard activityIndicator.superview == nil else {
            return
        }
        presentedViewController.view.addSubview(activityIndicator)
        let safeAreaHeight = UIApplication.shared.currentWindow?.safeAreaInsets.top ?? 0
        NSLayoutConstraint.activate([
            activityIndicator.topAnchor.constraint(equalTo: presentedViewController.view.topAnchor, constant: 30 + safeAreaHeight),
            activityIndicator.centerXAnchor.constraint(equalTo: presentedViewController.view.centerXAnchor)
        ])
    }

    private static func hideIndicator() {
        activityIndicator.removeFromSuperview()
    }


}
