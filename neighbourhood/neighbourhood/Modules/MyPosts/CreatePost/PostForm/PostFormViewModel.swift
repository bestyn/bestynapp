//
//  PostFormViewModel.swift
//  neighbourhood
//
//  Created by Artem Korzh on 20.11.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import GooglePlaces
import Photos

class PostFormViewModel {

    private var postSaver: PostSaver { .shared }

    private(set) var type: TypeOfPost
    private var latitude: Float?
    private var longitude: Float?
    private var placeId: String?
    private var postID: Int?

    private let addressFormatter = AddressFormatter()

    private let validation = ValidationManager()
    private lazy var postsManager: RestMyPostsManager = {
        let manager: RestMyPostsManager = RestService.shared.createOperationsManager(from: self)
        manager.assignErrorHandler { [weak self] (error) in
            self?.lastError = error
        }
        return manager
    }()

    public var existingImagesCount: Int {
        postSaver.mediaToDisplay.filter { (media) -> Bool in
            if case .localImage = media {
                return true
            }
            if case .remoteImage = media {
                return true
            }
            return false
        }.count
    }

    public var existingVideosCount: Int {
        postSaver.mediaToDisplay.filter { (media) -> Bool in
            if case .localVideo = media {
                return true
            }
            if case .remoteVideo = media {
                return true
            }
            return false
        }.count
    }

    // MARK: - Observables

    @Observable var lastError: Error? {
        didSet {
            if lastError != nil {
                lastError = nil
            }
        }
    }
    @Observable var hashtags: [HashtagModel] = []
    @Observable var isLoading: Bool = false
    @Observable var isSending: Bool = false
    @Observable private(set) var selectedStartDate: Date?
    @Observable private(set) var selectedEndDate: Date?
    @Observable private(set) var selectedAddress: String?
    @Observable private(set) var mediaToDisplay: [PostFormMedia] = []
    @Observable private(set) var isSaved: Bool = false

    private(set) var postDescription: String!
    private(set) var offerPrice: String?
    private(set) var eventName: String?

    var isEditMode: Bool { postSaver.postToEdit != nil }
    var postToEdit: PostModel? { postSaver.postToEdit }

    init() {
        let postSaver = PostSaver.shared
        type = postSaver.postToEdit?.type ?? postSaver.type
        postDescription = postSaver.postDescription
        selectedStartDate = postSaver.selectedStartDate
        selectedEndDate = postSaver.selectedEndDate
        selectedAddress = postSaver.selectedAddress
        mediaToDisplay = postSaver.mediaToDisplay
        eventName = postSaver.eventName
        offerPrice = postSaver.offerPrice
    }
}

// MARK: - Public methods

extension PostFormViewModel {

    func setStartDate(_ date: Date) {
        selectedStartDate = date
        postSaver.setStartDate(date)
    }

    func setEndDate(_ date: Date) {
        selectedEndDate = date
        postSaver.setEndDate(date)
    }

    func setPlace(_ place: GMSPlace) {
        postSaver.setPlace(place)
        selectedAddress = postSaver.selectedAddress
    }

    func addImage(croppedImage: UIImage, uploadData: UploadImageData) {
        postSaver.addImage(croppedImage: croppedImage, uploadData: uploadData)
        mediaToDisplay = postSaver.mediaToDisplay
    }

    func updateCrop(croppedImage: UIImage, uploadData: UploadImageData, at index: Int) {
        postSaver.updateCrop(croppedImage: croppedImage, uploadData: uploadData, at: index)
        mediaToDisplay = postSaver.mediaToDisplay
    }

    func addVideo(url: URL) {
        postSaver.addVideo(url: url)
        mediaToDisplay = postSaver.mediaToDisplay
    }

    func removeMedia(_ media: PostFormMedia) {
        postSaver.removeMedia(media)
        mediaToDisplay = postSaver.mediaToDisplay
    }

    public func setDescription(_ description: String) {
        self.postDescription = description
        postSaver.setDescription(description)
    }

    public func setPrice(_ price: String) {
        self.offerPrice = price
        postSaver.setPrice(price)
    }

    public func setEventName(_ name: String) {
        self.eventName = name
        postSaver.setEventName(name)
    }

    func save() {
        postSaver.save()
        self.isSaved = true
    }

    func addLocalAudio(url: URL) {
        postSaver.addLocalAudio(url: url)
        mediaToDisplay = postSaver.mediaToDisplay
    }

    func removeAudio(url: URL) {
        postSaver.removeAudio(url: url)
        mediaToDisplay = postSaver.mediaToDisplay
    }

    func addCroppedImage(image: UIImage) {
        postSaver.addCroppedImage(image: image)
        mediaToDisplay = postSaver.mediaToDisplay
    }
}

// MARK: - GallerySelectorDelegate

extension PostFormViewModel: GallerySelectorDelegate {
    func mediaSelected(entities: [GallerySelectionEntity]) {
        for entity in entities {
            if case .video(let asset) = entity {
                if let urlAsset = asset as? AVURLAsset {
                    addVideo(url: urlAsset.url)
                }
                break
            }
            if case .image(let image) = entity {
                addCroppedImage(image: image)
            }
        }
    }

    func canSelectMore(mediaType: GallerySelectorMediaType, imagesSelected: Int, videosSelected: Int) -> Bool {


        switch mediaType {
        case .image:
            if existingVideosCount + videosSelected > 0 {
                Toast.show(message: "You can only select 5 photos or 1 video at once.")
                return false
            }
            if existingImagesCount + imagesSelected == 5 {
                Toast.show(message: R.string.localizable.maxMediaSelected())
                return false
            }
            return true
        case .video:
            if existingImagesCount + imagesSelected > 0 {
                Toast.show(message: "You can only select 5 photos or 1 video at once.")
                return false
            }
            if existingVideosCount + videosSelected == 1 {
                Toast.show(message: R.string.localizable.maxMediaSelected())
                return false
            }
            return true
        }
    }
}

extension PostFormViewModel: RecordVoiceDelegate {
    func audioRecorded(url: URL) {
        addLocalAudio(url: url)
    }
}
