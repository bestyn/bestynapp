//
//  StorySaver.swift
//  neighbourhood
//
//  Created by Artem Korzh on 19.03.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import Foundation

class StorySaver: ErrorHandling {

    static let shared = StorySaver()

    private(set) var isPublishing = false

    lazy var storiesManager: RestStoriesManager = RestService.shared.createOperationsManager(from: self)

    var storyCreator: StoryCreator { StoryCreator.shared }

    func createStory(with data: StoryData) {
        print("START PUBLISHING")
        Toast.show(message: "Your story is publishing. Please do not close the application until the story has been published.")
        isPublishing = true
        storyCreator.createVideo { [weak self] (url, error) in
            if let error = error {
                self?.handleError(error)
                self?.isPublishing = false
                return
            }
            if let url = url {
                self?.restCreateStory(data: data, fileURL: url)
            }
        }
    }

    private func restCreateStory(data: StoryData, fileURL: URL) {
        storiesManager.createStory(data: data, fileURL: fileURL)
            .onError({ [weak self] (error) in
                self?.handleError(error)
                self?.isPublishing = false
            })
            .onComplete({ [weak self] (_) in
                self?.storyCreator.reset()
                ArchiveService.shared.hasPostedStories = true
                self?.isPublishing = false
                NotificationCenter.default.post(name: .postCreated, object: TypeOfPost.story)
                Toast.show(message: "Your story has been successfully published.")
                print("END PUBLISHING")
            })
            .run()
    }
}
