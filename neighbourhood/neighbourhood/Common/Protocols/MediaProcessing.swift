//
//  AvatarChanging.swift
//  neighbourhood
//
//  Created by Dioksa on 07.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//
import UIKit

enum MediaProcessingOption {
    case gallery(title: String? = nil)
    case galleryImage(title: String? = nil)
    case galleryVideo(title: String? = nil)
    case capture(title: String? = nil)
    case captureImage(title: String? = nil)
    case captureVideo(title: String? = nil)
    case file(title: String? = nil)
    case remove(title: String? = nil)
}

enum MediaProcessingResult {
    case image(UIImage, URL?)
    case video(URL)
    case file(URL)
    case remove
}

protocol MediaProcessorDelegate: class {
    func mediaOptionProcessed(result: MediaProcessingResult)
}

class MediaProcessor: NSObject {

    private weak var viewController: UIViewController!
    private weak var delegate: MediaProcessorDelegate!

    lazy var imagePicker: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.delegate = self
        return picker
    }()

    lazy var documentPicker: UIDocumentPickerViewController = {
        let picker = UIDocumentPickerViewController(documentTypes: GlobalConstants.Common.docTypes, in: .import)
        picker.delegate = self
        return picker
    }()

    init(viewController: UIViewController, delegate: MediaProcessorDelegate) {
        self.viewController = viewController
        self.delegate = delegate
    }

    func openMediaOptions(_ options: [MediaProcessingOption]) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.view.tintColor = R.color.secondaryBlack()

        for option in options {
            switch option {
            case .gallery(let title):
                if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                    alert.addAction(UIAlertAction(
                        title: title ?? R.string.localizable.selectFromGallery(),
                        style: .default,
                        handler: { (_) in
                        self.openGallery(photo: true, video: true)
                    }))
                }
            case .galleryImage(let title):
                if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                    alert.addAction(UIAlertAction(
                        title: title ?? R.string.localizable.selectImageFromGallery(),
                        style: .default,
                        handler: { (_) in
                        self.openGallery(photo: true, video: false)
                    }))
                }
            case .galleryVideo(let title):
                if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                    alert.addAction(UIAlertAction(
                        title: title ?? R.string.localizable.selectVideoFromGallery(),
                        style: .default,
                        handler: { (_) in
                        self.openGallery(photo: false, video: true)
                    }))
                }
            case .capture(let title):
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    alert.addAction(UIAlertAction(
                        title: title ?? R.string.localizable.startCamera(),
                        style: .default,
                        handler: { (_) in
                            self.openCamera(photo: true, video: true)
                    }))
                }
            case .captureImage(let title):
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    alert.addAction(UIAlertAction(
                        title: title ?? R.string.localizable.takePhoto(),
                        style: .default,
                        handler: { (_) in
                            self.openCamera(photo: true, video: false)
                    }))
                }
            case .captureVideo(let title):
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    alert.addAction(UIAlertAction(
                        title: title ?? R.string.localizable.makeVideo(),
                        style: .default,
                        handler: { (_) in
                            self.openCamera(photo: false, video: true)
                    }))
                }
            case .file(let title):
                alert.addAction(UIAlertAction(
                    title: title ?? R.string.localizable.file(),
                    style: .default,
                    handler: { (_) in
                    self.selectFile()
                }))
            case .remove(let title):
                alert.addAction(UIAlertAction(
                    title: title ?? R.string.localizable.removePhoto(),
                    style: .destructive,
                    handler: { (_) in
                        self.delegate.mediaOptionProcessed(result: .remove)
                    }))
            }
        }

        alert.addAction(UIAlertAction(
            title: R.string.localizable.cancelTitle(),
            style: .cancel,
            handler: nil))

        viewController.present(alert, animated: true, completion: nil)
    }

    func selectFile() {
        documentPicker.modalPresentationStyle = .formSheet
        viewController.present(documentPicker, animated: true, completion: nil)
    }
    
    private func openCamera(photo: Bool = true, video: Bool = false) {
        imagePicker.sourceType = .camera
        
        var mediaTypes: [String] = []
        if photo {
            mediaTypes.append("public.image")
        }
        if video {
            mediaTypes.append("public.movie")
        }
        imagePicker.mediaTypes = mediaTypes
        
        viewController.present(imagePicker, animated: true, completion: nil)
    }

    private func openGallery(photo: Bool = true, video: Bool = false) {
        imagePicker.sourceType = .savedPhotosAlbum
        var mediaTypes: [String] = []
        if photo {
            mediaTypes.append("public.image")
        }
        if video {
            mediaTypes.append("public.movie")
        }
        imagePicker.mediaTypes = mediaTypes
        viewController.present(imagePicker, animated: true, completion: nil)
    }
}

extension MediaProcessor: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) {
            if let image = info[.originalImage] as? UIImage {
                let imageURL = info[.imageURL] as? URL
                self.delegate.mediaOptionProcessed(result: .image(image, imageURL))
            } else if let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
                self.delegate.mediaOptionProcessed(result: .video(url))
            }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension MediaProcessor: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        controller.dismiss(animated: true) {
            if let url = urls.first {
                self.delegate.mediaOptionProcessed(result: .file(url))
            }
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}
