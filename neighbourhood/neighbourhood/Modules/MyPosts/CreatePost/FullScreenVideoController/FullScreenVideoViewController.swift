//
//  FullScreenVideoViewController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 26.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import AVKit

class FullScreenVideoViewController: BaseViewController {

    let videoURL: URL
    var player: AVPlayer!
    var playerObserver: NSKeyValueObservation!

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    init(videoURL: URL) {
        self.videoURL = videoURL
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPlayer()
    }

    private func setupPlayer() {
        let controller = AVPlayerViewController()
        player = AVPlayer(url: videoURL)
        player.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions(rawValue: 0), context: nil)
        controller.player = player
        controller.setValue(false, forKey: "canHidePlaybackControls")
        view.addSubview(controller.view)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            controller.view.topAnchor.constraint(equalTo: view.topAnchor),
            controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            controller.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controller.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        addChild(controller)
        controller.didMove(toParent: self)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if object as? NSObject == player, keyPath == "status" {
            if player.status == .readyToPlay {
                setupDownloadButton()
                player.play()
            }
        }
    }
    private func setupDownloadButton() {
        guard let controller = children.first as? AVPlayerViewController,
              let containerView = controller.view.subviews.first?.subviews.last?.subviews.first else {
            return
        }

        let button = UIButton()
        button.backgroundColor = UIColor(red: 0.141, green: 0.141, blue: 0.161, alpha: 1)
        button.cornerRadius = 14
        button.addTarget(self, action: #selector(download), for: .touchUpInside)
        button.setImage(R.image.download_video_icon(), for: .normal)
        view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false


        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: containerView.topAnchor) ,
            button.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -76),
            button.widthAnchor.constraint(equalToConstant: 60),
            button.heightAnchor.constraint(equalToConstant: 47)
        ])
    }


    @objc private func download() {
        player.pause()
        DownloadService.saveVideoToGallery(videoURL: videoURL)
    }
}
