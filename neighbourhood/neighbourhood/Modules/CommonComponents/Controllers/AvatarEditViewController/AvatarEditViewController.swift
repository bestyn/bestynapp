//
//  AvatarEditViewController.swift
//  neighbourhood
//
//  Created by Dioksa on 08.07.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

protocol AvatarEditViewControllerDelegate: class {
    func avatarComplete(originalImage: UIImage, croppedImage: UIImage, crop: CGRect)
}

class AvatarEditViewController: BaseViewController {

    @IBOutlet private weak var saveButton: DarkButton!
    @IBOutlet private weak var maskedImageView: MaskedImageView!

    private let image: UIImage
    private var initCrop: Rect?

    public weak var delegate: AvatarEditViewControllerDelegate?

    init(image: UIImage, initialCrop: Rect? = nil) {
        self.initCrop = initialCrop
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    @IBAction func closeButtonDidTap(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapSave(_ sender: Any) {
        save()
    }
}

// MARK: - Inner logic
extension AvatarEditViewController {
    private func setupUI() {
        if let initCrop = initCrop {
            maskedImageView.cropParameters = initCrop.cgRect
        }
        maskedImageView.image = image
    }

    private func save() {
        guard let image = maskedImageView.image,
              let croppedImage = maskedImageView.resultImage else {
            return
        }
        dismiss(animated: true) {
            self.delegate?.avatarComplete(originalImage: image, croppedImage: croppedImage, crop: self.maskedImageView.cropParameters)
        }
    }
}
