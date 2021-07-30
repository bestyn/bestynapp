//
//  PostSaver.swift
//  neighbourhood
//
//  Created by Artem Korzh on 05.04.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import UIKit
import GooglePlaces

enum PostFormMedia {
    case remoteImage(MediaDataModel)
    case localImage(UIImage, UploadImageData)
    case remoteVideo(MediaDataModel)
    case localVideo(URL)
    case remoteAudio(MediaDataModel)
    case localAudio(URL)

    var audioURL: URL? {
        switch self {
        case .localAudio(let url):
            return url
        case .remoteAudio(let media):
            return media.origin
        default:
            return nil
        }
    }
}

class PostSaver: ErrorHandling {

    static let shared = PostSaver()

    private let addressFormatter = AddressFormatter()

    // MARK: - Post Data
    private(set) var postToEdit: PostModel?
    private var mediaToDelete: [MediaDataModel] = []
    private var mediaToUpload: [PostFormMedia] {
        mediaToDisplay.filter { (media) -> Bool in
            switch media {
            case .localVideo, .localImage, .localAudio:
                return true
            default:
                return false
            }
        }
    }
    private(set) var mediaToDisplay: [PostFormMedia] = []
    private var isEditing = false
    private var lastSavedPost: PostModel?
    private(set) var type: TypeOfPost = .general
    private(set) var selectedStartDate: Date?
    private(set) var selectedEndDate: Date?
    private(set) var selectedAddress: String?
    private(set) var postDescription: String!
    private(set) var offerPrice: String?
    private var price: Double? {
        var price: Double?
        if type == .offer, let priceString = self.offerPrice?.replacingOccurrences(of: ",", with: ".", options: NSString.CompareOptions.literal, range:nil),
            let finalPrice = Double(priceString) {
            price = finalPrice
        }
        return price
    }
    private(set) var eventName: String?
    private var latitude: Float?
    private var longitude: Float?
    private var placeId: String?

    private var postData: PostData {
        return .init(
            description: postDescription,
            address: selectedAddress,
            placeId: placeId,
            price: price,
            name: eventName,
            startDatetime: selectedStartDate?.timeIntervalSince1970,
            endDatetime: selectedEndDate?.timeIntervalSince1970,
            latitude: latitude,
            longitude: longitude)
    }

    public func edit(post: PostModel) {
        self.reset()
        self.postToEdit = post
        self.isEditing = true
        self.mediaToDisplay = post.media?.map({ mediaModel -> PostFormMedia in
            switch mediaModel.type {
            case .video:
                return .remoteVideo(mediaModel)
            case .image:
                return .remoteImage(mediaModel)
            case .voice:
                return .remoteAudio(mediaModel)
            }
        }) ?? []
        postDescription = post.description
        selectedStartDate = post.startDatetime
        selectedEndDate = post.endDatetime
        selectedAddress = post.address
        placeId = post.placeId
        if let price = post.price {
            offerPrice = String(format: "%.2f", price)
                .replacingOccurrences(of: ",", with: ".", options: NSString.CompareOptions.literal, range: nil)
        }
        eventName = post.name
    }

    public func createPost(type: TypeOfPost) {
        self.reset()
        self.type = type
        self.isEditing = false
    }

    public func reset() {
        postToEdit = nil
        type = .general
        mediaToDelete = []
        mediaToDisplay = []
        lastSavedPost = nil
        selectedStartDate = nil
        selectedEndDate = nil
        selectedAddress = nil
        postDescription = nil
        offerPrice = nil
        eventName = nil
        latitude = nil
        longitude = nil
        placeId = nil
    }

    // MARK: - Post saver state
    private(set) var isPublishing = false

    private lazy var postsManager: RestMyPostsManager = {
        let manager: RestMyPostsManager = RestService.shared.createOperationsManager(from: self)
        manager.assignErrorHandler { [weak self] (error) in
            self?.handleError(error)
        }
        return manager
    }()

    public func save() {
        isPublishing = true
        Toast.show(message: R.string.localizable.postPublishBegin())
        let completion = { [weak self] in
            guard let self = self else {
                return
            }
            self.modifyAttachments(mediaData: .init(mediaToUpload: self.mediaToUpload, mediaToDelete: self.mediaToDelete))
        }
        isEditing
            ? restUpdatePost(postId: postToEdit!.id, type: postToEdit!.type, data: postData, completion: completion)
            : restStorePost(type: type, data: postData, completion: completion)
    }

    public func checkPostFormAvailability() -> Bool {
        if isPublishing {
            Toast.show(message: R.string.localizable.postPublishInProgress())
            return false
        }
        return true
    }

    func setStartDate(_ date: Date) {
        selectedStartDate = date
    }

    func setEndDate(_ date: Date) {
        selectedEndDate = date
    }

    func setPlace(_ place: GMSPlace) {
        latitude = Float(place.coordinate.latitude)
        longitude = Float(place.coordinate.longitude)
        placeId = place.placeID

        selectedAddress = addressFormatter.getAddressFromPlace(place)?.addressString
    }

    func addImage(croppedImage: UIImage, uploadData: UploadImageData) {
        mediaToDisplay.append(.localImage(croppedImage, uploadData))
    }

    func updateCrop(croppedImage: UIImage, uploadData: UploadImageData, at index: Int) {
        mediaToDisplay[index] = .localImage(croppedImage, uploadData)
    }

    func addVideo(url: URL) {
        mediaToDisplay.append(.localVideo(url))
    }

    func removeMedia(_ media: PostFormMedia) {
        let mediaToDeleteIndex = mediaToDisplay.firstIndex(where: { (storedMedia) -> Bool in
            switch media {
            case .localImage(let image, _):
                if case .localImage(let storedImage, _) = storedMedia, storedImage == image {
                    return true
                }
            case .localVideo(let url):
                if case .localVideo(let storedURL) = storedMedia, storedURL == url {
                    return true
                }
            case .localAudio(let url):
                if case .localAudio(let storedURL) = storedMedia, storedURL == url {
                    return true
                }
            case .remoteImage(let media):
                if case .remoteImage(let storedMediaData) = storedMedia, storedMediaData.id == media.id {
                    self.mediaToDelete.append(media)
                    return true
                }
            case .remoteVideo(let media):
                if case .remoteVideo(let storedMediaData) = storedMedia, storedMediaData.id == media.id {
                    self.mediaToDelete.append(media)
                    return true
                }
            case .remoteAudio(let media):
                if case .remoteAudio(let storedMediaData) = storedMedia, storedMediaData.id == media.id {
                    self.mediaToDelete.append(media)
                    return true
                }
            }

            return false
        })
        if let mediaToDeleteIndex = mediaToDeleteIndex {
            mediaToDisplay.remove(at: mediaToDeleteIndex)
        }
    }

    public func setDescription(_ description: String) {
        self.postDescription = description
    }

    public func setPrice(_ price: String) {
        self.offerPrice = price
    }

    public func setEventName(_ name: String) {
        self.eventName = name
    }

    public func addLocalAudio(url: URL) {
        mediaToDisplay.append(.localAudio(url))
    }

    public func removeAudio(url: URL) {
        guard let media = mediaToDisplay.first(where: {$0.audioURL == url}) else {
            return
        }
        removeMedia(media)
    }

    public func addCroppedImage(image: UIImage) {
        let cropSize: CGSize = {
            let ratio: CGFloat = 1.6
            let imageRatio = image.size.width / image.size.height
            if imageRatio > ratio {
                return CGSize(width: image.size.height * ratio, height: image.size.height)
            } else {
                return CGSize(width: image.size.width, height: image.size.width / ratio)
            }
        }()
        let cropRect = CGRect(
            origin: CGPoint(
                x: (image.size.width - cropSize.width) / 2,
                y: (image.size.height - cropSize.height) / 2),
            size: cropSize)
        guard let resultImage = image.fixOrientation().crop(rect: cropRect) else {
            return
        }
        addImage(croppedImage: resultImage, uploadData: .init(image: image, crop: .init(cgRect: cropRect)))
    }

}

// MARK: - Private methods

extension PostSaver {

    private func completeSave() {
        if let lastSavedPost = lastSavedPost {
            isEditing
                ? NotificationCenter.default.post(name: .postUpdated, object: lastSavedPost)
                : NotificationCenter.default.post(name: .postCreated, object: lastSavedPost.type)
            Toast.show(message: R.string.localizable.postPublishEnded())
        }
        self.lastSavedPost = nil
        isEditing = false
        isPublishing = false
        self.reset()
    }

    private func modifyAttachments(mediaData: PostMediaData) {
        guard let lastSavedPost = lastSavedPost else {
            completeSave()
            return
        }
        if mediaData.mediaToUpload.count == 0,
           mediaData.mediaToDelete.count == 0 {
            completeSave()
            return
        }

        let mediaGroup = DispatchGroup()

        for media in mediaData.mediaToDelete {
            mediaGroup.enter()
            deleteMedia(media: media) {
                mediaGroup.leave()
            }
        }
        for media in mediaData.mediaToUpload {
            mediaGroup.enter()
            uploadMedia(postID: lastSavedPost.id, media: media) {
                mediaGroup.leave()
            }
        }

        mediaGroup.notify(queue: .main) { [weak self] in
            self?.restFetchPost(id: lastSavedPost.id) { [weak self] post in
                self?.lastSavedPost = post
                self?.completeSave()
            }
        }
    }

    private func uploadMedia(postID: Int, media: PostFormMedia, completion: @escaping () -> Void) {
        switch media {
        case .localImage(_, let imageData):
            restAddImage(postID: postID, imageData: imageData) {
                completion()
            }
        case .localVideo(let url):
            url.encodeVideo { [weak self] (encodedURL, error) in
                if let error = error {
                    self?.handleError(error)
                    completion()
                    return
                }
                if let encodedURL = encodedURL {
                    self?.restAddVideo(postID: postID, videoURL: encodedURL, completion: completion)
                }
            }
        case .localAudio(let url):
            self.restAddAudio(postID: postID, audioURL: url, completion: completion)
        default:
            break
        }
    }

    private func deleteMedia(media: MediaDataModel, completion: @escaping () -> Void) {
        restDeleteMedia(media: media, completion: completion)
    }
}

// MARK: - REST

extension PostSaver {

    private func restDeleteMedia(media: MediaDataModel, completion: @escaping () -> Void ) {
        postsManager.deleteMediaToPost(mediaId: media.id)
            .onError({ (_) in })
            .onStateChanged { (state) in
                if state == .ended {
                    completion()
                }
            }.run()
    }

    private func restStorePost(type: TypeOfPost, data: PostData, completion: @escaping () -> Void) {
        postsManager.addPost(postType: type, data: data)
            .onComplete { [weak self] (result) in
                AnalyticsService.logPostCreated(type: type)
                if let post = result.result {
                    self?.lastSavedPost = post
                }
                completion()
            }.run()
    }

    private func restUpdatePost(postId: Int, type: TypeOfPost, data: PostData, completion: @escaping () -> Void) {
        postsManager.updatePost(postType: type, postId: postId, data: data)
            .onComplete { [weak self] (response) in
                if let post = response.result {
                    self?.lastSavedPost = post
                }
                completion()
            }.run()
    }

    func restAddImage(postID: Int, imageData: UploadImageData, completion: @escaping () -> Void) {
        postsManager.addImageToPost(postID: postID, imageData: imageData)
            .onError({ (_) in })
            .onStateChanged { (state) in
                if state == .ended {
                    completion()
                }
            }.run()
    }

    func restAddVideo(postID: Int, videoURL: URL, completion: @escaping () -> Void) {
        postsManager.addVideoToPost(postID: postID, videoURL: videoURL)
            .onError({ (_) in })
            .onStateChanged { (state) in
                if state == .ended {
                    completion()
                }
            }.run()
    }

    func restAddAudio(postID: Int, audioURL: URL, completion: @escaping () -> Void) {
        postsManager.addAudioToPost(postID: postID, audioURL: audioURL)
            .onStateChanged { (state) in
                if state == .ended {
                    completion()
                }
            }.run()
    }

    private func restFetchPost(id: Int, completion: @escaping (PostModel) -> Void) {
        postsManager.getPost(postId: id)
            .onComplete { (response) in
                if let post = response.result {
                    completion(post)
                }
            }.run()
    }
}
