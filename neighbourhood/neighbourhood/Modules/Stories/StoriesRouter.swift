//
//  StoriesRouter.swift
//  neighbourhood
//
//  Created by Artem Korzh on 16.02.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import GBKRouterProtocol

struct StoriesRouter: GBKRouterProtocol {
    var context: UINavigationController!

    public func openAudioStoriesList(audio: AudioTrackModel, anchorStory: PostModel? = nil) {
        let controller = StoriesListViewController(mode: .audio(audio), anchorStory: anchorStory)
        controller.withBackButton = true
        controller.delegate = controller
        push(controller: controller)
    }
}
