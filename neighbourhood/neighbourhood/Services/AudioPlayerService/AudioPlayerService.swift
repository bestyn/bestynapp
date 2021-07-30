//
//  AudioPlayerService.swift
//  neighbourhood
//
//  Created by Artem Korzh on 01.02.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import UIKit
import AVFoundation

class AudioPlayerService {
    static let shared = AudioPlayerService()

    private let cacheManager = CacheManager.of(type: .file)
    private(set) var isPlaying = false {
        didSet {
            if isPlaying {
                player.play()
                NotificationCenter.default.post(name: .audioTrackPlaying, object: currentURL)
            } else {
                player.pause()
                NotificationCenter.default.post(name: .audioTrackPaused, object: currentURL)
            }
        }
    }
    private var hasPlaying = false
    private(set) var isFetching = false
    private(set) var currentURL: URL!
    private lazy var player: AVPlayer = {
        let player = AVPlayer()
        player.volume = 1
        playerObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: .main, using: { [weak self] (time) in
            guard let url = self?.currentURL else {
                return
            }
            NotificationCenter.default.post(name: .audioTrackProgress, object: (url, time.seconds))
        })
        return player
    }()
    private var playerObserver: Any?

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleForeground), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    deinit {
        if let playerObserver = playerObserver {
            player.removeTimeObserver(playerObserver)
            self.playerObserver = nil
        }
        NotificationCenter.default.removeObserver(self)
    }

    public func play(url: URL) {
        if currentURL == url {
            isPlaying = true
            return
        }
        isPlaying = false
        isFetching = true
        currentURL = url
        func process(localURL: URL?) {
            guard self.currentURL == url else {
                return
            }
            isFetching = false
            player.pause()
            if let localURL = localURL {
                player.replaceCurrentItem(with: AVPlayerItem(url: localURL))
            } else {
                player.replaceCurrentItem(with: AVPlayerItem(url: url))
            }
            NotificationCenter.default.addObserver(self, selector: #selector(handleEndPlaying(notification:)),
                                                   name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
            isPlaying = true
        }
        cacheManager.get(url: url) { [weak self] (localURL) in
            if let localURL = localURL {
                process(localURL:  localURL)
                return
            }
            self?.cacheManager.insert(url: url, completion: nil)
            process(localURL: nil)
        }
    }

    public func pause() {
        guard isPlaying else {
            return
        }
        isPlaying = false
    }

    public func stop() {
        if isPlaying {
            isPlaying = false
        }
        player.seek(to: .zero)
    }

    public func seek(url: URL, to second: Double) {
        guard currentURL == url else {
            return
        }
        player.seek(to: CMTime(seconds: second, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
    }

    @objc private func handleEndPlaying(notification: Notification) {
        isPlaying = false
        player.seek(to: .zero)
    }

    @objc private func handleBackground() {
        guard isPlaying else {
            return
        }
        hasPlaying = true
        isPlaying = false
    }

    @objc private func handleForeground() {
        guard hasPlaying else {
            return
        }
        hasPlaying = false
        isPlaying = true
    }
}
