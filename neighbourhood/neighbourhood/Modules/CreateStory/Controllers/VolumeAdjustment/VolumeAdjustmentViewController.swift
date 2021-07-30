//
//  VolumeAdjustmentViewController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 08.02.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import UIKit

protocol VolumeAdjustmentViewControllerDelegate: class {
    func volumeChanged()
}

class VolumeAdjustmentViewController: UIViewController, BottomMenuPresentable {
    var transitionManager: BottomMenuPresentationManager! = .init()
    var presentedViewHeight: CGFloat { stackView.frame.height }

    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var originalVolumeSlider: UISlider!
    @IBOutlet weak var addedVolumeSlider: UISlider!

    private var storyCreator: StoryCreator { .shared }
    public weak var delegete: VolumeAdjustmentViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        originalVolumeSlider.value = storyCreator.originalVolume
        addedVolumeSlider.value = storyCreator.addedVolume
        if storyCreator.mode == .text {
            originalVolumeSlider.isEnabled = false
        }
    }

    @IBAction func didChangeOriginalVolume(_ sender: UISlider) {
        storyCreator.changeVolume(track: .original, volume: sender.value)
        delegete?.volumeChanged()
    }

    @IBAction func didCHangeAddedVolume(_ sender: UISlider) {
        storyCreator.changeVolume(track: .added, volume: sender.value)
        delegete?.volumeChanged()
    }

    @objc public func close() {
        dismiss(animated: true)
    }
}
