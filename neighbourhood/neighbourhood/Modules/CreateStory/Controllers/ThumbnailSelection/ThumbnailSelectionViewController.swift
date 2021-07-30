//
//  ThumbnailSelectionViewController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 16.12.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

protocol ThumbnailSelectionViewControllerDelegate: class {
    func thumbnailSecondSelected(_ second: Int)
}

class ThumbnailSelectionViewController: UIViewController {

    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var videoSlider: VideoSlider!

    private let assetParams: VideoAssetParams
    private var selectedSecond: Int
    weak var delegate: ThumbnailSelectionViewControllerDelegate?

    init(assetParams: VideoAssetParams, selectedSecond: Int) {
        self.assetParams = .init(asset: assetParams.asset, videoComposition: assetParams.layerComposition, layerComposition: nil, audioMix: nil)
        self.selectedSecond = selectedSecond
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        videoSlider.delegate = self
        videoSlider.mode = .frameSelection
        videoSlider.withTime = false
        self.videoSlider.params = .init(assetParams: assetParams, range: nil)
        videoSlider.frameTime = .init(seconds: Double(selectedSecond), preferredTimescale: 600)
        coverImageView.image = FrameGenerator().single(from: assetParams, at: Double(selectedSecond))
    }

    @IBAction func didTapCancel(_ sender: Any) {
        close()
    }

    @IBAction func didTapDone(_ sender: Any) {
        delegate?.thumbnailSecondSelected(selectedSecond)
        close()
    }

    private func close() {
        dismiss(animated: true)
    }
}


extension ThumbnailSelectionViewController: VideoSliderDelegate {
    func rangeChanged(_ range: ClosedRange<Double>) {
    }
    
    func frameChanged(second: Double) {
        let roundedSecond = round(second)
        guard roundedSecond >= 1, roundedSecond < assetParams.asset.duration.seconds else {
            return
        }
        coverImageView.image = FrameGenerator().single(from: assetParams, at: roundedSecond)
        selectedSecond = Int(roundedSecond)
    }

    func dragEnded() {

    }

    func dragStarted() {
        
    }


}
