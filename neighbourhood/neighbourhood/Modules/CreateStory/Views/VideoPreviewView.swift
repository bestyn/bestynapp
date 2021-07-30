//
//  VideoPreviewView.swift
//  neighbourhood
//
//  Created by Artem Korzh on 27.11.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import AVFoundation

class VideoPreviewView: UIView {

    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
        }
        layer.videoGravity = .resizeAspectFill
        return layer
    }

    var session: AVCaptureSession? {
        get { videoPreviewLayer.session }
        set { videoPreviewLayer.session = newValue }
    }


}
