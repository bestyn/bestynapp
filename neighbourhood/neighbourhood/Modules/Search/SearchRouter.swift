//
//  SearchRouter.swift
//  neighbourhood
//
//  Created by Artem Korzh on 23.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import GBKRouterProtocol

struct SearchRouter: GBKRouterProtocol {
    var context: UINavigationController!

    func openSearch() {
        let controller = SearchViewController()
        push(controller: controller)
    }

    func openAudioDetails(for audioTrack: AudioTrackModel) {
        let controller = AudioDetailsViewController(audioTrack: audioTrack)
        push(controller: controller)
    }
}

