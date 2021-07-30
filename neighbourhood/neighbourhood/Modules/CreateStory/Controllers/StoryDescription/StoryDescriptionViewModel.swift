//
//  StoryDescriptionViewModel.swift
//  neighbourhood
//
//  Created by Artem Korzh on 04.12.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import UIKit
import GooglePlaces

class StoryDescriptionViewModel {

    var storyCreator: StoryCreator { .shared }
    let postToEdit: PostModel?

    private lazy var storiesManager: RestStoriesManager = {
        let manager = RestService.shared.createOperationsManager(from: self, type: RestStoriesManager.self)
        manager.assignExecutionHandler { [weak self] (state) in
            if state == .ended {
                self?.isSaving = false
            }
        }
        manager.assignErrorHandler { [weak self] (error) in
            self?.saveResult = .failure(error)
        }
        return manager
    }()

    @Observable private(set) var thumbnailImage: UIImage?
    @Observable private(set) var selectedAddress: String?
    @Observable private(set) var isSaving: Bool = false
    @Observable private(set) var selectedSecond: Int = 1 {
        didSet {
            updateThumbnailFromCreatedVideo()
        }
    }
    @Observable private(set) var saveResult: Result<Void, Error>? = nil
    var isEditMode: Bool { postToEdit != nil }

    private var latitude: Float?
    private var longitude: Float?
    private(set) var placeId: String?

    private let addressFormatter = AddressFormatter()

    init(postToEdit: PostModel?) {
        self.postToEdit = postToEdit
        if let postToEdit = postToEdit {
            loadPostInfo(post: postToEdit)
        } else {
            updateThumbnailFromCreatedVideo()
        }

    }

    private func loadPostInfo(post: PostModel) {
        if let url = post.media?.first?.formatted?.thumbnail {
            UIImage.load(from: url) { (image) in
                self.thumbnailImage = image
            }
        }
        selectedAddress = post.address
        placeId = post.placeId
    }

    private func updateThumbnailFromCreatedVideo() {
        storyCreator.getThumbnail(at: selectedSecond) { (image) in
            self.thumbnailImage = image
        }
    }
}

extension StoryDescriptionViewModel {

    public func save(description: String, allowComments: Bool, allowDuet: Bool) {
        isSaving = true
        if let postToEdit = postToEdit {
            let data = StoryData(description: description, allowedComment: true, allowedDuet: allowDuet, placeId: placeId, latitude: latitude, longitude: longitude)
            restUpdateStory(id: postToEdit.id, data: data)
        } else {
            let data = StoryData(description: description, allowedComment: true, allowedDuet: allowDuet, posterTime: selectedSecond, placeId: placeId, latitude: latitude, longitude: longitude, audioId: storyCreator.backgroundSong?.track.id)
            StorySaver.shared.createStory(with: data)
            saveResult = .success(())
        }
    }

    public func setSelectedAddress(place: GMSPlace) {
        latitude = Float(place.coordinate.latitude)
        longitude = Float(place.coordinate.longitude)
        placeId = place.placeID

        selectedAddress = addressFormatter.getAddressFromPlace(place)?.addressString
    }

    public func setSelectedThumbnailSecond(_ second: Int) {

    }
}

extension StoryDescriptionViewModel {

    private func restUpdateStory(id: Int, data: StoryData) {
        storiesManager.updateStory(id: id, data: data)
            .onComplete({ [weak self] (result) in
                self?.saveResult = .success(())
                self?.storyCreator.reset()
                if let post = result.result {
                    NotificationCenter.default.post(name: .postUpdated, object: post)
                }
            })
            .run()
    }
}

extension StoryDescriptionViewModel: ThumbnailSelectionViewControllerDelegate {
    func thumbnailSecondSelected(_ second: Int) {
        selectedSecond = second
    }
}
