//
//  FrameGenerator.swift
//  neighbourhood
//
//  Created by Artem Korzh on 16.12.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import AVFoundation
import UIKit

struct VideoAssetParams {
    let asset: AVAsset
    let videoComposition: AVVideoComposition?
    let layerComposition: AVVideoComposition?
    let audioMix: AVAudioMix?
}

struct FrameGenerator {

    func multiple(from assetParams: VideoAssetParams, framesCount: Int32 = 10, completion: @escaping ([UIImage]) -> Void) {
        let generator = AVAssetImageGenerator(asset: assetParams.asset)
        generator.videoComposition = assetParams.videoComposition
        generator.requestedTimeToleranceAfter = .zero
        generator.requestedTimeToleranceBefore = .zero
        generator.appliesPreferredTrackTransform = true
        let seconds = assetParams.asset.duration.seconds
        var images: [UIImage] = []
        DispatchQueue.global(qos: .userInitiated).async {
            for frame in 0..<framesCount {
                let time = CMTime(seconds: min(seconds, seconds * Double(frame) / Double(framesCount) + 0.5), preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                if let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) {
                    images.append(.init(cgImage: cgImage))
                }
            }
            DispatchQueue.main.async {
                completion(images)
            }
        }
    }

    func single(from assetParams: VideoAssetParams, at seconds: Double) -> UIImage? {
        let generator = AVAssetImageGenerator(asset: assetParams.asset)
        generator.videoComposition = assetParams.videoComposition
        if let cgImage = try? generator.copyCGImage(at: .init(seconds: seconds, preferredTimescale: 600), actualTime: nil) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
}
