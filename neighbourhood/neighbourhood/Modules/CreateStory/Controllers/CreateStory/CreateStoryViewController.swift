//
//  CreateStoryViewController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 26.11.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class CreateStoryViewController: BaseStoryRecordViewController {

    @IBOutlet var durationButtons: [UIButton]!
    @IBOutlet weak var galleryButton: DoubleBorderedButton!
    @IBOutlet weak var textStoryButton: UIButton!
    @IBOutlet weak var durationButtonsStackView: UIStackView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    var createStoryViewModel: CreateStoryViewModel { viewModel as! CreateStoryViewModel }

    override init() {
        super.init()
        viewModel = CreateStoryViewModel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupDurationButtons()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupGalleryButton()
    }

    // MARK: - Override

    override func setupViewModel() {
        super.setupViewModel()
        guard let viewModel = self.viewModel as? CreateStoryViewModel else {
            return
        }
        viewModel.$gallerySelected.bind { [weak self] (selected) in
            guard let self = self, selected == true else {
                return
            }
            CreateStoryRouter(in: self.navigationController).openGalleryClipAdjustment()
        }
        viewModel.$galleryProcessing.bind { [weak self] (isProcessing) in
            self?.loadingIndicator.isHidden = !isProcessing
            self?.view.isUserInteractionEnabled = !isProcessing
        }
    }

    override func updateDuration(_ durations: [Double]) {
        super.updateDuration(durations)
        [galleryButton, textStoryButton].forEach { (button) in
            button?.alpha = durations.count > 0 ? 0 : 1
            button?.isEnabled = durations.count == 0
        }
    }

    override func updateRecordingState(isRecording: Bool) {
        super.updateRecordingState(isRecording: isRecording)
        durationButtonsStackView.isHidden = isRecording || viewModel.recordedDurations.count > 0
    }

    // MARK: - IBActions

    @IBAction func didTapFilters(_ sender: Any) {
    }

    @IBAction func didTapSpeed(_ sender: Any) {
    }

    @IBAction func didTapGallery(_ sender: Any) {
        openGallery()
    }

    @IBAction func didTapTextStory(_ sender: Any) {
        CreateStoryRouter(in: navigationController).openTextStoryCreation()
    }
}

// MARK: - Configuration

extension CreateStoryViewController {
    private func setupDurationButtons() {
        durationButtons.forEach { (button) in
            button.setBackgroundColor(color: UIColor.white.withAlphaComponent(0.2), forState: .normal)
            button.setBackgroundColor(color: UIColor.white.withAlphaComponent(0.6), forState: .disabled)
            button.addTarget(self, action: #selector(didTapDuration(button:)), for: .touchUpInside)
        }
        durationButtons.last?.isEnabled = false
    }

    private func setupGalleryButton() {
        PermissionsService(shouldAskPermissions: false).checkPermission(types: [.gallery]) { (result) in
            if result.allGranted {
                let galleryService = GalleryService()
                if let asset = galleryService.fetchAssets(type: .all).firstObject {
                    galleryService.image(asset: asset, size: .init(width: 40, height: 40)) { (image) in
                        if let image = image {
                            self.galleryButton.setImage(image, for: .normal)
                        }
                    }
                }

            }
        }
    }
}

// MARK: - Private actions

extension CreateStoryViewController {
    @objc func didTapDuration(button: UIButton) {
        guard let index = durationButtons.firstIndex(of: button) else {
            return
        }
        durationButtons.forEach({$0.isEnabled = true})
        button.isEnabled = false
        createStoryViewModel.selectMaxDuration(duration: createStoryViewModel.durations[index])
    }

    private func openGallery() {
        PermissionsService().checkPermission(types: [.gallery]) { [weak self] (result) in
            guard result.allGranted else {
                Alert(title: Alert.Title.galleryPermissions, message: Alert.Message.galleryPermissions(appName: Configuration.appName))
                    .configure(doneText: Alert.Action.openSettings)
                    .configure(cancelText: Alert.Action.cancel)
                    .show { (result) in
                        if result == .done,
                           let url = URL(string: UIApplication.openSettingsURLString),
                           UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }
                return
            }
            if let self = self {
                GallerySelectorRouter(in: self.navigationController).openGallerySelection(delegate: self.createStoryViewModel)
            }
        }
    }
}
