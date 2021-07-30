//
//  CreateOrEditPostViewController.swift
//  neighbourhood
//
//  Created by Dioksa on 21.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import TagListView
import GoogleMaps
import GooglePlaces
import GBKSoftTextField
import AVKit

protocol PostFormDelegate: AnyObject {
    func newPostAdded(post: PostModel)
    func postUpdated(post: PostModel)
}

private let staticRowHeight: CGFloat = 28.0
private let maxRowCount: CGFloat = 5.0
private let priceFormat = "XXX,XXX.XX"
private let maxLoadedImagesCount = 5

final class PostFormViewController: BaseViewController {
    @IBOutlet private weak var screenTitleLabel: UILabel!
    
    @IBOutlet private weak var scrollView: MediaScrollView!
    @IBOutlet private weak var pageControll: UIPageControl!
    @IBOutlet private weak var addAttachmentView: AddAttachmentView!
    @IBOutlet private weak var addedPhotosStackView: UIStackView!
    @IBOutlet private weak var addedPhotoTitleLabel: UILabel!
    @IBOutlet private weak var smallAttachmentButton: UIButton!

    @IBOutlet private weak var addressTextField: CustomTextField!
    @IBOutlet private weak var priceTextField: CustomTextField!
    @IBOutlet private weak var eventNameTextField: CustomTextField!
    @IBOutlet private weak var startDateTextField: CustomTextField!
    @IBOutlet private weak var endDateTextField: CustomTextField!
    
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var descriptionTextView: UITextView!
    @IBOutlet private weak var descriptionErrorLabel: UILabel!
    @IBOutlet private weak var descriptionBottomView: UIView!
    
    @IBOutlet private weak var postButton: DarkButton!
    @IBOutlet private weak var bottomView: UIView!
    @IBOutlet private weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var hashtagsTableView: UITableView!

    private let screenType: TypeOfPost
    private var categories: [CategoriesData]?
    private var currentPost: PostModel?
    private var selectedStartDate: Date?
    private var selectedEndDate: Date?
    private var latitude: Float?
    private var longitude: Float?
    private var placeId: String?
    private var selectedVideoUrl: URL?
    private var relatedHashtags: [HashtagModel] = []
    
    private let startDatePicker = UIDatePicker()
    private let endDatePicker = UIDatePicker()
    private let helper = PageScrollingHelper()
    private lazy var gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(addButtonDidTap))
    private lazy var tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(openFullScreen))
    private var selectedCategories = [CategoriesData]()
    private let validation = ValidationManager()
    private let addressFormatter = AddressFormatter()
    private lazy var postsManager: RestMyPostsManager = {
        let manager = RestService.shared.createOperationsManager(from: self, type: RestMyPostsManager.self)
        manager.assignErrorHandler { [weak self] (error) in
            self?.handleError(error)
        }
        return manager
    }()
    private lazy var categoriesManager: RestCategoriesManager = RestService.shared.createOperationsManager(from: self, type: RestCategoriesManager.self)
    private lazy var mediaProcessor: MediaProcessor = MediaProcessor(viewController: self, delegate: self)

    private var imageViews = [UIImageView]()
    private var newImages = [UploadImageData]()
    private var mediaToDelete = [MediaDataModel]()
    private var originalMedia = [MediaDataModel]()
    
    weak var tabsDelegate: PostFormDelegate?
    var action: TypeOfScreenAction = .create
    private var savedPost: PostModel?
    var postIdToEdit: Int?

    private var mediaToUpload: Int = 0

    override var preferredStatusBarStyle: UIStatusBarStyle { .default }
    
    init(screenType: TypeOfPost) {
        self.screenType = screenType
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setDelegates()
        addAttachmentView.addGestureRecognizer(gestureRecognizer)
        configurePickers()
        
        if action == .edit && postIdToEdit != nil {
            spinner.startAnimating()
            fetchCurrentPost(by: postIdToEdit!)
        }
        hashtagsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "hashtagCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if action == .edit {
            postButton.setTitle(R.string.localizable.saveButtonTitle(), for: .normal)
        }
    }

    override func setupViewUI() {
        spinner.stopAnimating()
        setTexts()
        defineElementsVisibility()
        bottomView.dropShadow(color: R.color.greyStroke()!, opacity: 0.3, offSet: CGSize(width: 0, height: -5), radius: 3.0)
        pageControll.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
    }

    override var isBottomPaddingNeeded: Bool {
        return false
    }

    // MARK: - Private actions
    @IBAction private func postButtonDidTap(_ sender: UIButton) {
        if formIsValid() {
            guard let id = ArchiveService.shared.currentProfile?.id else {
                NSLog("🔥 Profile id is nil at CreateOrEditPostViewController")
                return
            }

            switch action {
            case .create:
                savePost(type: screenType)
            case .edit:
                updatePost(profileId: id, type: screenType)
            }
        } else if screenType != .general && screenType != .news {
            Toast.show(message: "Please check entered data again")
        }
    }

    @IBAction private func closeButtonDidTap(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction private func topSmallAddButtonDidTap(_ sender: UIButton) {
        mediaProcessor.openMediaOptions([
            .gallery(withVideo: imageViews.isEmpty),
            .camera(withVideo: imageViews.isEmpty)
        ])
    }

    @IBAction func didTapHashtags(_ sender: Any) {
    }
}

// MARK: - Internal logic
extension PostFormViewController {
    private func setDelegates() {
        descriptionTextView.delegate = self
        startDateTextField.delegate = self
        endDateTextField.delegate = self
    }
    
    private func createImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        let button = UIButton(frame: CGRect(x: UIScreen.main.bounds.width - 90, y: 10, width: 40, height: 40))
        button.setImage(R.image.remove_image_button(), for: .normal)
        button.addTarget(self, action: #selector(removeButtonAction), for: .touchUpInside)
        imageView.addSubview(button)
        imageView.bringSubviewToFront(button)
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapRecognizer)
        
        return imageView
    }
    
    private func createImageWithButton(_ url: URL?) {
        guard let mediaUrl = url else { return }
        
        let asset = AVURLAsset(url: mediaUrl, options: nil)
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        guard let cgImage = try? imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil) else { return }
        var uiImage = UIImage(cgImage: cgImage)
        if let track = asset.tracks(withMediaType: .video).first {
            let size = track.naturalSize
            let transform = track.preferredTransform
            if (size.width == transform.tx && size.height == transform.ty) {
                uiImage = uiImage.rotate(radians: .pi )
            } else if (transform.tx == size.height && transform.ty == 0) {
                uiImage = uiImage.rotate(radians: .pi / 2)
            } else if (transform.tx == 0 && transform.ty == size.width) {
                uiImage = uiImage.rotate(radians:  -.pi / 2)
            }
        }
        let imageView = self.createImageView()
        imageView.image = uiImage
        
        imageViews = [imageView]
        
        let playerButton = UIButton(frame: CGRect(x: (scrollView.frame.width / 2) - 40, y: (scrollView.frame.height / 2) - 40, width: 80, height: 80))
        playerButton.setImage(R.image.play_video_icon(), for: .normal)
        playerButton.isUserInteractionEnabled = false
        imageView.addSubview(playerButton)
        imageView.bringSubviewToFront(playerButton)
        
        configureScrollViewSubviews(pagesCount: 0, views: [imageView])
    }
    
    @objc private func addButtonDidTap() {
        mediaProcessor.openMediaOptions([
            .gallery(withVideo: imageViews.isEmpty),
            .camera(withVideo: imageViews.isEmpty)
        ])
    }
    
    @objc private func openFullScreen() {
        if let url = selectedVideoUrl {
            let player = AVPlayer(url: url)
            let controller = AVPlayerViewController()
            controller.player = player
            controller.view.frame = self.view.frame
            
            present(controller, animated: true) {
                player.play()
            }
        } else {
            guard !imageViews.isEmpty, let image = imageViews[pageControll.currentPage].image else {
                return
            }
            
            MyPostsRouter(in: navigationController).openImage(image: image)
        }
    }

    func removeAvatar() { }

    @objc private func startDatePickerDidTap() {
        selectedStartDate = startDatePicker.date.withoutSeconds
        startDateTextField?.text = startDatePicker.date.dateTimeString
    }
    
    @objc private func endDatePickerDidTap() {
        selectedEndDate = endDatePicker.date.withoutSeconds
        endDateTextField?.text = endDatePicker.date.dateTimeString
    }

    @objc private func recropImage() {
        let indexToRecrop = pageControll.currentPage

    }
    
    @objc private func removeButtonAction() {
        let indexToDelete = pageControll.currentPage
        if action == .edit, originalMedia.count > 0 {
            let oldImagesCount = originalMedia.count
            if indexToDelete < oldImagesCount {
                let media = originalMedia[indexToDelete]
                mediaToDelete.append(media)
                originalMedia.remove(at: indexToDelete)
            } else {
                newImages.remove(at: indexToDelete - oldImagesCount)
            }
        } else {
            if selectedVideoUrl != nil {
                selectedVideoUrl = nil
            } else {
                newImages.remove(at: indexToDelete)
            }
        }
        
        if !imageViews.isEmpty {
            imageViews.remove(at: indexToDelete)
        }
        
        smallAttachmentButton.isHidden = imageViews.count == maxLoadedImagesCount
        updateUI()
    }
    
    @objc private func removeVideoButtonAction() {
        if let media = currentPost?.media?.first, media.type == .video {
            mediaToDelete.append(media)
        }
        scrollView.subviews.forEach { $0.removeFromSuperview() }
        selectedVideoUrl = nil
        smallAttachmentButton.isHidden = false
        updateUI()
    }

    
}

// MARK: - Configurations
private extension PostFormViewController {

    func configurePickers() {
        startDatePicker.datePickerMode = .dateAndTime
        endDatePicker.datePickerMode = .dateAndTime
        startDatePicker.addTarget(self, action: #selector(startDatePickerDidTap), for: .valueChanged)
        endDatePicker.addTarget(self, action: #selector(endDatePickerDidTap), for: .valueChanged)
        startDateTextField.inputView = startDatePicker
        endDateTextField.inputView = endDatePicker
    }
    
    func setTexts() {
        addedPhotoTitleLabel.text = R.string.localizable.attachmentsAddedTitle()
        configureTextForScreenTitle()
        configureTextFieldsTitleAndPlaceholder()
        
        postButton.setTitle(screenType == .event
            ? R.string.localizable.createEventButtonTitle()
            : R.string.localizable.postButtonTitle(), for: .normal)
    }
    
    func configureTextFieldsTitleAndPlaceholder() {
        switch screenType {
        case .general:
            descriptionLabel.text = R.string.localizable.generalPostDescriptionTitle()
        case .news:
            descriptionLabel.text = R.string.localizable.newsDescriptionTitle()
        case .crime:
            addressTextField.title = R.string.localizable.addressTitle()
            addressTextField.placeholder = R.string.localizable.incidentAddressPlaceholder()
            descriptionLabel.text = R.string.localizable.crimeDescriptionTitle()
        case .offer:
            descriptionLabel.text = R.string.localizable.offerDescriptionTitle()
            priceTextField.title = R.string.localizable.priceInTitle()
            priceTextField.placeholder = " "
        case .event:
            eventNameTextField.title = R.string.localizable.eventNameTitle()
            eventNameTextField.placeholder = R.string.localizable.eventNamePlaceholder()
            addressTextField.title = R.string.localizable.eventAddressTitle()
            addressTextField.placeholder = R.string.localizable.eventAddressPlaceholder()
            startDateTextField.title = R.string.localizable.startDateTitle()
            startDateTextField.placeholder = " "
            endDateTextField.title = R.string.localizable.endTimeTitle()
            endDateTextField.placeholder = " "
            descriptionLabel.text = R.string.localizable.eventDescriptionTitle()
        default:
            break
        }
        
        descriptionTextView.text = R.string.localizable.yourMessagePlaceholder()
    }
    
    func configureTextForScreenTitle() {
        switch (screenType) {
        case .general:
            screenTitleLabel.text = action == .create ? R.string.localizable.createGeneralPostScreenTitle() : R.string.localizable.editGeneralPost()
        case .news:
            screenTitleLabel.text = action == .create ? R.string.localizable.shareNewsScreenTitle() : R.string.localizable.editNewsPost()
        case .crime:
            screenTitleLabel.text = action == .create ? R.string.localizable.tellAboutCrimeScreenTitle() : R.string.localizable.editCrimePost()
        case .offer:
            screenTitleLabel.text = action == .create ? R.string.localizable.createOfferScreenTitle() : R.string.localizable.editOfferPost()
        case .event:
            screenTitleLabel.text = action == .create ? R.string.localizable.createEventScreenTitle() : R.string.localizable.editEvent()
        default:
            break
        }
    }
    
    func defineElementsVisibility() {
        addressTextField.isHidden = [.general, .news, .offer].contains(screenType)
        priceTextField.isHidden = ![.offer].contains(screenType)
        eventNameTextField.isHidden = ![.event].contains(screenType)
        startDateTextField.isHidden = ![.event].contains(screenType)
        endDateTextField.isHidden = ![.event].contains(screenType)
        
        if action == .edit {
            addAttachmentView.isHidden = true
            scrollView.isHidden = false
            pageControll.isHidden = false
            addedPhotosStackView.isHidden = false
        } else {
            updateUI()
        }
    }
    
    func updateUI() {
        let hasImagesToShow = !imageViews.isEmpty
        addAttachmentView.isHidden = hasImagesToShow
        scrollView.isHidden = false
        pageControll.isHidden = !hasImagesToShow
        addedPhotosStackView.isHidden = !hasImagesToShow
        pageControll.numberOfPages = imageViews.count

        scrollView.views = imageViews
    }
    
    func fillFieldsWithData() {
        if let categories = currentPost?.categories, !categories.isEmpty {
            selectedCategories = categories
        }
        
        fillLabelText()
        descriptionTextView.textColor = R.color.mainBlack()
        defineMediaTypeConfiguration()
    }
    
    private func fillLabelText() {
        eventNameTextField.text = currentPost?.name
        startDateTextField.text = currentPost?.startDatetime?.dateTimeString
        selectedStartDate = currentPost?.startDatetime
        endDateTextField.text = currentPost?.endDatetime?.dateTimeString
        selectedEndDate = currentPost?.endDatetime
        descriptionTextView.text = currentPost?.description
        addressTextField.text = currentPost?.address
        placeId = currentPost?.placeId
        
        if let price = currentPost?.price {
            priceTextField.text = String(format: "%.2f", price)
                .replacingOccurrences(of: ",", with: ".", options: NSString.CompareOptions.literal, range: nil)
        }
    }
    
    private func defineMediaTypeConfiguration() {
        guard let media = currentPost?.media, !media.isEmpty else {
            updateUI()
            return
        }

        originalMedia = media
        if media.first?.type == .video {
            guard let url = media.first?.formatted?.origin else { return }
            smallAttachmentButton.isHidden = true
            selectedVideoUrl = url
            createImageWithButton(url)
        } else if media.first?.type == .image {
            imageViews = media.map { $0.origin }.map { (url) -> UIImageView in
                let imageView = self.createImageView()
                imageView.load(from: url, withLoader: true, completion: {})
                return imageView
            }
            
            smallAttachmentButton.isHidden = imageViews.count > 4
            configureScrollViewSubviews(pagesCount: imageViews.count, views: imageViews)
        }
    }
}

// MARK: - Form procession

private extension PostFormViewController {
    func formIsValid() -> Bool {
        var valid = true
        let validation = ValidationManager()
        
        [addressTextField, priceTextField, eventNameTextField, startDateTextField, endDateTextField].forEach( {$0?.error = nil} )
        
//        if let validationError = validation
//            .validateInterests(value: selectedCategories)
//            .errorMessage(field: categoryTextField.title ?? "") {
//            categoryTextField.error = validationError.capitalizingFirstLetter()
//            valid = false
//        }
        
        if let validationError = validation
            .validatePostDescription(value: descriptionTextView.text == R.string.localizable.yourMessagePlaceholder() ? nil : descriptionTextView.text)
            .errorMessage(field: descriptionLabel.text ?? "") {
            descriptionErrorLabel.isHidden = false
            descriptionBottomView.backgroundColor = R.color.accentRed()
            descriptionErrorLabel.text = validationError.capitalizingFirstLetter()
            valid = false
        } else {
            descriptionErrorLabel.isHidden = true
            descriptionBottomView.backgroundColor = R.color.greyStroke()
        }
        
        if screenType == .crime || screenType == .event {
            if let validationError = validation
                .validateRequired(value: addressTextField.text)
                .errorMessage(field: R.string.localizable.addressTitle()) {
                addressTextField.error = validationError.capitalizingFirstLetter()
                valid = false
            }
        }
        
        if screenType == .offer {
            if let validationError = validation
                .validatePrice(value: priceTextField.text)
                .errorMessage(field: priceTextField.title ?? "") {
                priceTextField.error = validationError.capitalizingFirstLetter()
                valid = false
            }
        }
        
        if screenType == .event {
            if let validationError = validation
                .validateEventName(value: eventNameTextField.text)
                .errorMessage(field: eventNameTextField.title ?? "") {
                eventNameTextField.error = validationError.capitalizingFirstLetter()
                valid = false
            }
            
            if let endDate = selectedEndDate, let startDate = selectedStartDate, endDate < startDate {
                endDateTextField.error = ValidationErrors().wrongEndEventDate(field: endDateTextField.title ?? "", startEventDate: startDateTextField?.text ?? "")
                valid = false
            }
        }
        
        if valid && !validation.checkInternetConnection() {
            Toast.show(message: R.string.localizable.internetConnectionError())
        }
        
        return valid
    }
    
    func savePost(type: TypeOfPost) {
        let categoriesIds = selectedCategories.map { $0.id }.map { $0 }

        var price: Double?
        if type == .offer, let priceString = priceTextField.text?.replacingOccurrences(of: ",", with: ".", options: NSString.CompareOptions.literal, range:nil),
            let finalPrice = Double(priceString) {
            price = finalPrice
        }
        
        let data = PostData(description: descriptionTextView.text!,
                                 categories: categoriesIds,
                                 address: addressTextField.text,
                                 placeId: placeId,
                                 price: price,
                                 name: eventNameTextField.text,
                                 startDatetime: selectedStartDate?.timeIntervalSince1970,
                                 endDatetime: selectedEndDate?.timeIntervalSince1970,
                                 latitude: latitude,
                                 longitude: longitude)

        restStorePost(type: type, data: data)
    }
    
    func addPostAttachment(postId: Int?) {
        guard let postId = postId else {
            NSLog("No post id to send at CreatePostViewController")
            return }
        
        if !newImages.isEmpty {
            mediaToUpload = newImages.count
            uploadNextImage(postId: postId)
        }
        
        if selectedVideoUrl != nil {
            mediaToUpload = 1
            selectedVideoUrl!.encodeVideo() { (url, error) in
                guard let url = url else {
                    return
                }
                self.restAddVideo(postID: postId, videoURL: url) { [weak self] in
                    self?.mediaToUpload -= 1
                    self?.checkIfPostComplete()
                }
            }
        } else {
            checkIfPostComplete()
        }
    }

    private func uploadNextImage(postId: Int) {
        restAddImage(postID: postId, imageData: newImages.removeFirst()) { [weak self] in
            guard let self = self else {
                return
            }
            self.mediaToUpload -= 1
            if self.newImages.count > 0 {
                self.uploadNextImage(postId: postId)
                return
            }
            self.checkIfPostComplete()
        }
    }

    private func checkIfPostComplete() {
        guard mediaToUpload <= 0, mediaToDelete.count == 0 else {
            return
        }
        if action == .create {
            Toast.show(message: screenType == .event ? R.string.localizable.eventPublished() : R.string.localizable.postCreated())
        } else {
            Toast.show(message: screenType == .event ? R.string.localizable.eventUpdated() : R.string.localizable.postUpdated())
        }
        NotificationCenter.default.post(name: .postCreated, object: nil)
        dismiss(animated: true) {
            guard let post = self.savedPost else {
                return
            }
            if self.action == .create {
                self.tabsDelegate?.newPostAdded(post: post)
            } else {
                self.tabsDelegate?.postUpdated(post: post)
            }
        }
    }
    
    func fetchCurrentPost(by id: Int) {
        guard let profileId = ArchiveService.shared.currentProfile?.id else {
            NSLog("🔥 Profile id is nil at CreateOrEditPostViewController")
            return
        }
        
        restFetchPost(profileId: profileId, postId: id)
    }
    
    func updatePost(profileId: Int, type: TypeOfPost) {
        guard let postId = postIdToEdit else {
            NSLog("🔥 Post id is nil at CreateOrEditPostViewController")
            return
        }
        let categoriesIds = selectedCategories.map { $0.id }.map { $0 }
        var priceString = priceTextField.text
        if priceTextField.text?.contains(",") ?? false {
            let price = priceTextField.text?.replacingOccurrences(of: ",", with: ".", options: NSString.CompareOptions.literal, range: nil)
            priceString = price
        }
        
        let data = PostData(description: descriptionTextView.text!,
                                 categories: categoriesIds,
                                 address: addressTextField.text,
                                 placeId: placeId,
                                 price: Double(priceString!),
                                 name: eventNameTextField.text,
                                 startDatetime: selectedStartDate?.timeIntervalSince1970,
                                 endDatetime: selectedEndDate?.timeIntervalSince1970,
                                 latitude: latitude,
                                 longitude: longitude)

        restUpdatePost(postId: postId, type: type, data: data)
    }

    private func appendImage(_ image: UIImage) {
        let imageView = createImageView()
        imageView.image = image
        let button = UIButton(frame: CGRect(x: 90, y: 10, width: 40, height: 40))
        button.setImage(R.image.recrop_image_icon(), for: .normal)
        button.addTarget(self, action: #selector(recropImage), for: .touchUpInside)
        imageViews.append(imageView)
        updateUI()
        scrollView.setContentOffset(scrollView.subviews.last!.frame.origin, animated: false)
        pageControll.currentPage = imageViews.count - 1
        smallAttachmentButton.isHidden = imageViews.count >= maxLoadedImagesCount
    }

    private func appendVideo(_ url: URL) {
        selectedVideoUrl = url
        createImageWithButton(url)
        addedPhotosStackView.isHidden = false
        smallAttachmentButton.isHidden = true
        addAttachmentView.isHidden = true
        scrollView.isHidden = false
    }
}

// MARK: - Rest requests
extension PostFormViewController {
    private func restDeleteMedia(media: MediaDataModel) {
        postsManager.deleteMediaToPost(mediaId: media.id)
            .onComplete { [weak self] (_) in
                self?.mediaToDelete.removeAll(where: {$0.id == media.id})
                self?.checkIfPostComplete()
        } .run()
    }

    private func restStorePost(type: TypeOfPost, data: PostData) {
        postsManager.addPost(postType: type, data: data)
            .onStateChanged({ [weak self] (state) in
                if state == .started {
                    self?.postButton.isLoading = true
                }
            })
            .onComplete { [weak self] (result) in
                AnalyticsService.logPostCreated(type: type)
                guard let post = result.result else {
                    return
                }
                self?.savedPost = post
                self?.addPostAttachment(postId: post.id)
        } .onError { [weak self] (error) in
            self?.handleError(error)
        } .run()
    }
    
    private func restUpdatePost(postId: Int, type: TypeOfPost, data: PostData) {
        postsManager.updatePost(postType: type, postId: postId, data: data)
            .onStateChanged{ [weak self] (state) in
                if state == .started {
                    self?.postButton.isLoading = true
                }
        } .onComplete { [weak self] (response) in
            guard let self = self, let post = response.result else { return }
            self.savedPost = post
            
            if self.mediaToDelete.count == 0,
                self.newImages.count == 0,
                self.selectedVideoUrl == self.currentPost?.media?.first?.formatted?.origin || self.selectedVideoUrl == nil {
                Toast.show(message: type == .event ? R.string.localizable.eventUpdated() : R.string.localizable.postUpdated())
                self.dismiss(animated: true) {
                    self.tabsDelegate?.postUpdated(post: post)
                }
                return
            }
            
            if !self.mediaToDelete.isEmpty {
                self.mediaToDelete.forEach(self.restDeleteMedia(media:))
            }
            
            if !self.newImages.isEmpty {
                self.mediaToUpload = self.newImages.count
                self.addPostAttachment(postId: postId)
            }
            
            if self.selectedVideoUrl != nil, self.selectedVideoUrl != self.currentPost?.media?.first?.formatted?.origin {
                self.mediaToUpload = 1
                self.addPostAttachment(postId: postId)
            }
        } .onError { [weak self] (error) in
            self?.postButton.isLoading = false
            self?.handleError(error)
        } .run()
    }

    private func restFetchPost(profileId: Int, postId: Int) {
        postsManager.getPost(postType: screenType, postId: postId)
            .onStateChanged {  [weak self] (state) in
                switch state {
                case .started:
                    self?.spinner.startAnimating()
                case .ended:
                    self?.spinner.stopAnimating()
                }
        } .onComplete { [weak self] (result) in
            guard let strongSelf = self else { return }
            strongSelf.currentPost = result.result
            strongSelf.selectedCategories = result.result?.categories ?? []
            strongSelf.fillFieldsWithData()
        } .run()
    }

    func restAddImage(postID: Int, imageData: UploadImageData, completion: @escaping () -> Void) {
        postsManager.addImageToPost(postID: postID, imageData: imageData)
            .onComplete { _ in
                completion()
        } .run()
    }

    func restAddVideo(postID: Int, videoURL: URL, completion: @escaping () -> Void) {
        postsManager.addVideoToPost(postID: postID, videoURL: videoURL)
            .onComplete { [weak self] _ in
                self?.selectedVideoUrl = nil
                completion()
        } .run()
    }
}


// MARK: - UIScrollViewDelegate
extension PostFormViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageNumber = scrollView.contentOffset.x / (scrollView.frame.size.width)
        pageControll.currentPage = Int(pageNumber)
        pageControll.currentPageIndicatorTintColor = R.color.accentGreen()
    }
    
    private func configureScrollViewSubviews(pagesCount: Int, views: [UIView]) {
        scrollView.views = views
        pageControll.numberOfPages = pagesCount
    }
}

// MARK: - UITextFieldDelegate
extension PostFormViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch screenType {
        case .crime:
            switch textField {
            case descriptionTextView:
                addressTextField.becomeFirstResponder()
            default:
                view.endEditing(true)
            }
        case .offer:
            switch textField {
            case descriptionTextView:
                priceTextField.becomeFirstResponder()
            default:
                view.endEditing(true)
            }
        case .event:
            switch textField {
            case eventNameTextField:
                addressTextField.becomeFirstResponder()
            case addressTextField:
                startDateTextField.becomeFirstResponder()
            case startDateTextField:
                endDateTextField.becomeFirstResponder()
            case endDateTextField:
                descriptionTextView.becomeFirstResponder()
            default:
                view.endEditing(true)
            }
        default:
            break
        }
        
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        switch textField {
        case startDateTextField, endDateTextField:
            return false
        default:
            return true
        }
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == addressTextField {
            navigationController?.isNavigationBarHidden = true
            let bounds = GMSCoordinateBounds()
            
            let autocompleteController = GMSAutocompleteResultsViewController()
            autocompleteController.autocompleteBounds = bounds
            
            autocompleteController.secondaryTextColor = UIColor.white.withAlphaComponent(0.8)
            autocompleteController.primaryTextColor = UIColor.white.withAlphaComponent(0.6)
            autocompleteController.primaryTextHighlightColor = .white
            autocompleteController.tableCellBackgroundColor = .black
            autocompleteController.tableCellSeparatorColor = .white
            autocompleteController.tintColor = .white
            autocompleteController.autocompleteBoundsMode = .restrict
            autocompleteController.delegate = self
            
            let searchController = UISearchController(searchResultsController: autocompleteController)
            searchController.searchResultsUpdater = autocompleteController
            
            searchController.view.backgroundColor = .black
            searchController.searchBar.text = addressTextField.text
            searchController.searchBar.delegate = self
            
            let subView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 350.0, height: 45.0))
            
            subView.addSubview(searchController.searchBar)
            autocompleteController.view.addSubview(subView)
            autocompleteController.view.bringSubviewToFront(subView)
            searchController.searchBar.sizeToFit()
            searchController.hidesNavigationBarDuringPresentation = false
            
            definesPresentationContext = true
            present(searchController, animated: true, completion: nil)
            
            return false
        } else {
            return true
        }
    }
}

// MARK: - UISearchBarDelegate
extension PostFormViewController: UISearchBarDelegate {
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }
}

// MARK: - GMSAutocompleteResultsViewControllerDelegate
extension PostFormViewController: GMSAutocompleteResultsViewControllerDelegate {
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController, didFailAutocompleteWithError error: Error) {
        // TODO: - Handle error
    }
    
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didAutocompleteWith place: GMSPlace) {
        latitude = Float(place.coordinate.latitude)
        longitude = Float(place.coordinate.longitude)
        placeId = place.placeID

        let address = addressFormatter.getAddressFromPlace(place)
        addressTextField.text = address?.addressString
        addressTextField.error = nil

        resultsController.dismiss(animated: true, completion: nil)
    }
}

// MARK: - TagListViewDelegate
extension PostFormViewController: TagListViewDelegate {
    func tagRemoveButtonPressed(_ title: String, tagView: TagView, sender: TagListView) -> Void {
        if let index = selectedCategories.firstIndex(where: { $0.title == title }) {
            selectedCategories.remove(at: index)
        }
        
//        if selectedCategories.isEmpty {
//            if let validationError = validation
//                .validateInterests(value: selectedCategories)
//                .errorMessage(field: categoryTextField.title ?? "") {
//                categoryTextField.error = validationError
//            }
//        }
    }
}

// MARK: - UITextViewDelegate
extension PostFormViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        descriptionErrorLabel.isHidden = true
        descriptionBottomView.backgroundColor = R.color.greyStroke()
        
        if textView.textColor == R.color.greyMedium() {
            textView.text = nil
            textView.textColor = R.color.mainBlack()
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = R.string.localizable.yourMessagePlaceholder()
            textView.textColor = R.color.greyMedium()
        }
    }
}

// MARK: - GBKSoftTextFieldDelegate
extension PostFormViewController: GBKSoftTextFieldDelegate {
    func textFieldDidTapButton(_ textField: UITextField) {
        switch textField {
        case startDateTextField:
            startDateTextField.becomeFirstResponder()
        case endDateTextField:
            endDateTextField.becomeFirstResponder()
        default:
            break
        }
    }
}

// MARK: - ChoseCategoryDelegate
extension PostFormViewController: ChoseCategoryDelegate {
    func getCategory(by data: CategoriesData) {
        if !selectedCategories.contains(data) {
            selectedCategories.append(data)
        } else {
            Toast.show(message: R.string.localizable.categoryWasAddedError())
        }
    }
}

// MARK: - AvatarEditViewControllerDelegate
extension PostFormViewController: AvatarEditViewControllerDelegate {
    func avatarComplete(originalImage: UIImage, croppedImage: UIImage, crop: CGRect) {
        self.appendImage(croppedImage)
        newImages.append(UploadImageData(image: originalImage, crop: .init(cgRect: crop)))
    }
}

// MARK: - MediaProcessing

extension PostFormViewController: MediaProcessorDelegate {
    func mediaOptionProcessed(result: MediaProcessingResult) {
        switch result {
        case .image(let image, _):
            guard let compressedImage = image.compress(maxSizeMB: 350) else {
                return
            }
            self.present(MyPostsRouter().openAvatarEdit(image: compressedImage, delegate: self), animated: true)
        case .video(let url):
            let videoLength = NSData(contentsOf: url)?.length ?? 0

            if videoLength > GlobalConstants.Limits.videoFileLimit {
                Toast.show(message: R.string.localizable.bigVideoFileError())
            } else {
                appendVideo(url)
            }
        default:
            break
        }
    }
}


extension PostFormViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return relatedHashtags.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "hashtagCell", for: indexPath)
        cell.textLabel?.textColor = .black
        cell.textLabel?.font = R.font.poppinsRegular(size: 14)
        cell.textLabel?.text = relatedHashtags[indexPath.row].hashtag
        return cell
    }
}
