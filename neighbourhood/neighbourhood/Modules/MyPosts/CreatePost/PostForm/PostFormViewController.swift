//
//  PostFormViewController.swift
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
import GBKSoftRestManager

protocol PostFormDelegate: AnyObject {
    func newPostAdded(post: PostModel)
    func postUpdated(post: PostModel)
    func postRemoved(post: PostModel)
}

private enum Defaults {
    static let maxAudioFileSize = 350 * 1000 * 1000 // 350MB
    static let staticRowHeight: CGFloat = 28.0
    static let maxRowCount: CGFloat = 5.0
    static let priceFormat = "XXX,XXX.XX"
    static let maxLoadedImagesCount = 5
}


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
    
    @IBOutlet private weak var descriptionTextView: HashtagsTextView!
    
    @IBOutlet private weak var postButton: DarkButton!
    @IBOutlet private weak var bottomView: UIView!
    @IBOutlet private weak var spinner: UIActivityIndicatorView!
    @IBOutlet private weak var hashtagsTableView: UITableView!
    @IBOutlet private weak var nonHashtagsView: UIStackView!
    @IBOutlet private weak var textViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var addAudioView: UIView!
    @IBOutlet weak var audioListView: UIView!
    @IBOutlet weak var audioStackView: UIStackView!

    let viewModel: PostFormViewModel = .init()
    var delegate: PostFormDelegate?

    private let startDatePicker = UIDatePicker()
    private let endDatePicker = UIDatePicker()
    private let helper = PageScrollingHelper()
    private lazy var mediaProcessor: MediaProcessor = MediaProcessor(viewController: self, delegate: self)

    private lazy var imagePicker: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.delegate = self
        return picker
    }()

    private lazy var gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(addButtonDidTap))
    private var imageViews = [UIImageView]()
    private var currentMediaIndex: Int { pageControll.currentPage }
    private var isTextViewMaxHeight = false
    override var preferredStatusBarStyle: UIStatusBarStyle { .default }

    private lazy var audioViewShapeLayer: CAShapeLayer = {
        let backgroundLayer = CAShapeLayer()
        backgroundLayer.strokeColor = R.color.greyLight()?.cgColor
        backgroundLayer.lineWidth = 1
        backgroundLayer.lineDashPattern = [2,2]
        backgroundLayer.fillColor = UIColor.clear.cgColor
        addAudioView.layer.addSublayer(backgroundLayer)
        return backgroundLayer
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setDelegates()
        addAttachmentView.addGestureRecognizer(gestureRecognizer)
        configurePickers()
        setupViewModel()
        fillFieldsWithData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if viewModel.isEditMode {
            postButton.setTitle(R.string.localizable.saveButtonTitle(), for: .normal)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        audioViewShapeLayer.frame = addAudioView.bounds
        audioViewShapeLayer.path = UIBezierPath.verticalSymmetricShape(bounds: addAudioView.bounds, leftRadius: addAudioView.bounds.height / 2, rightRadius: 10).cgPath
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
        save()
    }

    @IBAction private func closeButtonDidTap(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction private func topSmallAddButtonDidTap(_ sender: UIButton) {
        addButtonDidTap()
    }

    @IBAction func didTapHashtags(_ sender: Any) {
        
    }

    @IBAction func didTapAddAudio(_ sender: Any) {
        showAddAudioMenu()
    }
}

// MARK: - Internal logic
extension PostFormViewController {
    private func setDelegates() {
        descriptionTextView.delegate = self
        startDateTextField.delegate = self
        endDateTextField.delegate = self
    }
    
    private func createImageView(cropable: Bool = false) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        let closeButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        closeButton.setImage(R.image.remove_image_button(), for: .normal)
        closeButton.addTarget(self, action: #selector(removeButtonAction), for: .touchUpInside)
        imageView.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -8)
        ])
        if cropable {
            let recropButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
            recropButton.setImage(R.image.recrop_image_icon(), for: .normal)
            recropButton.addTarget(self, action: #selector(recropButtonAction), for: .touchUpInside)
            imageView.addSubview(recropButton)
            recropButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                recropButton.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 8),
                recropButton.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 8)
            ])
            imageView.bringSubviewToFront(recropButton)
        }
        imageView.isUserInteractionEnabled = true
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(openFullScreen))
        imageView.addGestureRecognizer(tapRecognizer)
        
        return imageView
    }
    
    private func createImageWithButton(_ url: URL, thumbnail: URL?) -> UIImageView {
        let imageView = self.createImageView()
        let playerButton = UIButton(frame: CGRect(x: (scrollView.frame.width / 2) - 40, y: (scrollView.frame.height / 2) - 40, width: 80, height: 80))
        playerButton.setImage(R.image.play_video_icon(), for: .normal)
        playerButton.isUserInteractionEnabled = false
        imageView.addSubview(playerButton)
        imageView.bringSubviewToFront(playerButton)

        if let thumbnail = thumbnail {
            imageView.load(from: thumbnail, completion: {})
            return imageView
        }
        let asset = AVURLAsset(url: url, options: nil)
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        guard let cgImage = try? imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil) else { return imageView }
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
        imageView.image = uiImage
        
        return imageView
    }
    
    @objc private func addButtonDidTap() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(.init(title: R.string.localizable.selectImageFromGallery(), style: .default, handler: { [weak self] (_) in
            self?.openGallerySelector()
        }))
        if viewModel.existingImagesCount == 0 {
            alert.addAction(.init(title: R.string.localizable.selectVideoFromGallery(), style: .default, handler: { [weak self] (_) in
                self?.openGallerySelector()
            }))
        }
        alert.addAction(.init(title: R.string.localizable.takePhoto(), style: .default, handler: { [weak self] (_) in
            self?.openCamera(photo: true, video: false)
        }))
        if viewModel.existingImagesCount == 0 {
            alert.addAction(.init(title: R.string.localizable.makeVideo(), style: .default, handler: { [weak self] (_) in
                self?.openCamera(photo: false, video: true)
            }))
        }
        alert.addAction(.init(title: R.string.localizable.cancelTitle(), style: .cancel))
        present(alert, animated: true)
    }

    private func openCamera(photo: Bool, video: Bool) {
        imagePicker.sourceType = .camera

        var mediaTypes: [String] = []
        if photo {
            mediaTypes.append("public.image")
        }
        if video {
            mediaTypes.append("public.movie")
        }
        imagePicker.mediaTypes = mediaTypes
        present(imagePicker, animated: true)
    }

    private func openGallerySelector() {
        PermissionsService().checkPermission(types: [.gallery]) { [weak self] (result) in
            guard result.allGranted else {
                Alert(title: Alert.Title.galleryPermissions, message: Alert.Message.galleryPermissions(appName: Configuration.appName))
                    .configure(doneText: Alert.Action.openSettings)
                    .configure(cancelText: Alert.Action.cancel)
                    .show { (result) in
                        if result == .done,
                           let url = URL(string: UIApplication.openSettingsURLString),
                           UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }
                return
            }
            if let self = self {
                GallerySelectorRouter(in: self.navigationController).openGallerySelection(delegate: self.viewModel)
            }
        }
    }

    private func openVideo(url: URL) {
        let player = AVPlayer(url: url)
        let controller = AVPlayerViewController()
        controller.player = player
        controller.view.frame = self.view.frame

        present(controller, animated: true) {
            player.play()
        }
    }
    
    @objc private func openFullScreen() {
        switch  viewModel.mediaToDisplay.filter({ (media) -> Bool in
        switch media {
        case .localImage, .localVideo, .remoteVideo, .remoteImage:
            return true
        default:
            return false
        }
        })[currentMediaIndex] {
        case .localImage(_, let origin):
            MyPostsRouter(in: RootRouter.shared.rootNavigationController).openImage(image: origin.image)
        case .remoteImage(let media):
            MyPostsRouter(in: RootRouter.shared.rootNavigationController).openImage(imageUrl: media.origin)
        case .remoteVideo(let media):
            openVideo(url: media.origin)
        case .localVideo(let url):
            openVideo(url: url)
        case .localAudio, .remoteAudio:
            break
        }
    }

    func removeAvatar() { }

    @objc private func startDatePickerDidTap() {
        viewModel.setStartDate(startDatePicker.date.withoutSeconds)
    }
    
    @objc private func endDatePickerDidTap() {
        viewModel.setEndDate(endDatePicker.date.withoutSeconds)
    }

    @objc private func recropImage() {
        // TODO:
    }
    
    @objc private func removeButtonAction() {
        viewModel.removeMedia(viewModel.mediaToDisplay.filter({ (media) -> Bool in
            switch media {
            case .localImage, .localVideo, .remoteVideo, .remoteImage:
                return true
            default:
                return false
            }
        })[currentMediaIndex])
    }

    @objc private func recropButtonAction() {
        guard case .localImage(_, let uploadData) = viewModel.mediaToDisplay[currentMediaIndex] else {
            return
        }
        MyPostsRouter(in: navigationController).openAvatarEdit(image: uploadData.image, initCrop: uploadData.crop, delegate: self)
    }
    
    @objc private func removeVideoButtonAction() {
        viewModel.removeMedia(viewModel.mediaToDisplay.filter({ (media) -> Bool in
            switch media {
            case .localImage, .localVideo, .remoteVideo, .remoteImage:
                return true
            default:
                return false
            }
        })[0])
    }

    private func save() {
        guard formIsValid() else {
            return
        }
        viewModel.save()
    }

    private func showAddAudioMenu() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Select from Recordings", style: .default, handler: { [weak self] (_) in
            self?.openAudioPicker()
        }))
        alert.addAction(UIAlertAction(title: "Record a Voice Message", style: .default, handler: { [weak self] (_) in
            self?.openRecordAudio()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true)
    }

    private func openAudioPicker() {
        let pickerController = UIDocumentPickerViewController(documentTypes: GlobalConstants.Common.audioTypes, in: .import)
        pickerController.allowsMultipleSelection = true
        pickerController.delegate = self
        pickerController.modalPresentationStyle = .overCurrentContext
        present(pickerController, animated: true)
    }

    private func openRecordAudio() {
        MyPostsRouter(in: navigationController).openRecordVoice(delegate: viewModel)
    }
    
}

// MARK: - Configurations
private extension PostFormViewController {

    private func setupViewModel() {
        viewModel.$selectedStartDate.bind { [weak self] (date) in
            if let date = date {
                self?.startDatePicker.date = date
            }
            self?.startDateTextField.text = date?.eventDateTimeString
        }
        viewModel.$selectedEndDate.bind { [weak self] (date) in
            if let date = date {
                self?.endDatePicker.date = date
            }
            self?.endDateTextField.text = date?.eventDateTimeString
        }
        viewModel.$selectedAddress.bind { [weak self] (address) in
            self?.addressTextField.text = address
        }
        viewModel.$mediaToDisplay.bind { [weak self] (media) in
            self?.defineMediaTypeConfiguration(media: media)
        }
        viewModel.$isSending.bind { [weak self] (isSending) in
            self?.postButton.isLoading = isSending
        }
        viewModel.$isSaved.bind { [weak self] (isSaved) in
            guard let self = self, isSaved else {
                return
            }
            if self.viewModel.isEditMode {
                self.navigationController?.popViewController(animated: true)
            } else {
                MainScreenRouter(in: self.navigationController).openHomeFeed()
            }
        }
        viewModel.$lastError.bind { [weak self] (error) in
            guard let error = error else {
                return
            }
            if let apiError = error as? APIError,
               case .processingError(let status, let errorInfo) = apiError,
               status == 422, let info = errorInfo?.result {
                info.forEach { (fieldError) in
                    switch fieldError.field {
                    case "startDatetime":
                        self?.startDateTextField.error = ArchiveService.shared.config.error(code: fieldError.code, replacements: [])
                    case "endDatetime":
                        self?.endDateTextField.error = ArchiveService.shared.config.error(code: fieldError.code, replacements: [])
                    default:
                        return
                    }
                }
                return
            }

            self?.handleError(error)
        }
    }

    func configurePickers() {
        startDatePicker.datePickerMode = .dateAndTime
        startDatePicker.minimumDate = Date()
        endDatePicker.minimumDate = Date()
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
        
        postButton.setTitle(viewModel.type == .event
            ? R.string.localizable.createEventButtonTitle()
            : R.string.localizable.postButtonTitle(), for: .normal)
    }
    
    func configureTextFieldsTitleAndPlaceholder() {
        switch viewModel.type {
        case .general:
            descriptionTextView.title = R.string.localizable.generalPostDescriptionTitle()
        case .news:
            descriptionTextView.title = R.string.localizable.newsDescriptionTitle()
        case .crime:
            addressTextField.title = R.string.localizable.addressTitle()
            addressTextField.placeholder = R.string.localizable.incidentAddressPlaceholder()
            descriptionTextView.title = R.string.localizable.crimeDescriptionTitle()
        case .offer:
            descriptionTextView.title = R.string.localizable.offerDescriptionTitle()
            let priceTitle: String = R.string.localizable.priceInTitle("$")
            priceTextField.title = priceTitle
            let attributedTitle = NSMutableAttributedString(string: priceTitle)
            let currencyRange = (priceTitle as NSString).range(of: "$")
            attributedTitle.setAttributes([.foregroundColor: UIColor.green], range: currencyRange)
            priceTextField.placeholder = " "
            (priceTextField.subviews.first { (view) -> Bool in
                if let label = view as? UILabel, label.text == priceTextField.title {
                    return true
                }
                return false
            } as? UILabel)?.attributedText = attributedTitle
            priceTextField.setNeedsLayout()
        case .event:
            eventNameTextField.title = R.string.localizable.eventNameTitle()
            eventNameTextField.placeholder = R.string.localizable.eventNamePlaceholder()
            addressTextField.title = R.string.localizable.eventAddressTitle()
            addressTextField.placeholder = R.string.localizable.eventAddressPlaceholder()
            startDateTextField.title = R.string.localizable.startDateTitle()
            startDateTextField.placeholder = " "
            endDateTextField.title = R.string.localizable.endTimeTitle()
            endDateTextField.placeholder = " "
            descriptionTextView.title = R.string.localizable.eventDescriptionTitle()
        default:
            break
        }
        
        descriptionTextView.placeholder = R.string.localizable.postDescriptionPlaceholder()
    }
    
    func configureTextForScreenTitle() {
        switch (viewModel.type) {
        case .general:
            screenTitleLabel.text = !viewModel.isEditMode
                ? R.string.localizable.createGeneralPostScreenTitle()
                : R.string.localizable.editGeneralPost()
        case .news:
            screenTitleLabel.text = !viewModel.isEditMode
                ? R.string.localizable.shareNewsScreenTitle()
                : R.string.localizable.editNewsPost()
        case .crime:
            screenTitleLabel.text = !viewModel.isEditMode
                ? R.string.localizable.tellAboutCrimeScreenTitle()
                : R.string.localizable.editCrimePost()
        case .offer:
            screenTitleLabel.text = !viewModel.isEditMode
                ? R.string.localizable.createOfferScreenTitle()
                : R.string.localizable.editOfferPost()
        case .event:
            screenTitleLabel.text = !viewModel.isEditMode
                ? R.string.localizable.createEventScreenTitle()
                : R.string.localizable.editEvent()
        default:
            break
        }
    }
    
    func defineElementsVisibility() {
        addressTextField.isHidden = [.general, .news, .offer].contains(viewModel.type)
        priceTextField.isHidden = ![.offer].contains(viewModel.type)
        eventNameTextField.isHidden = ![.event].contains(viewModel.type)
        startDateTextField.isHidden = ![.event].contains(viewModel.type)
        endDateTextField.isHidden = ![.event].contains(viewModel.type)
        
        if viewModel.isEditMode {
            addAttachmentView.isHidden = true
            scrollView.isHidden = false
            pageControll.isHidden = false
            addedPhotosStackView.isHidden = false
        }
    }
    
    func updateUI() {
        let hasImagesToShow = imageViews.count > 0
        addedPhotosStackView.isHidden = !hasImagesToShow
        switch viewModel.mediaToDisplay.first {
        case .localVideo, .remoteVideo:
            smallAttachmentButton.isHidden = true
        default:
            smallAttachmentButton.isHidden =  !hasImagesToShow || imageViews.count == 5
        }
        addAttachmentView.isHidden = hasImagesToShow
        pageControll.isHidden = !hasImagesToShow
        pageControll.numberOfPages = imageViews.count

    }
    
    func fillFieldsWithData() {
        eventNameTextField.text = viewModel.eventName
        addressTextField.text = viewModel.selectedAddress
        descriptionTextView.text = viewModel.postDescription ?? ""
        priceTextField.text = viewModel.offerPrice
    }

    private func defineMediaTypeConfiguration(media: [PostFormMedia]) {
        imageViews = []
        audioStackView.arrangedSubviews.forEach({$0.removeFromSuperview()})
        audioListView.isHidden = true
        addAudioView.isHidden = false
        if media.isEmpty {
            updateUI()
            return
        }
        var audioCount = 0
        media.forEach { (mediaType) in
            switch mediaType {
            case .localImage(let image, _):
                let imageView = self.createImageView(cropable: true)
                imageView.image = image
                imageViews.append(imageView)
            case .remoteImage(let media):
                let imageView = self.createImageView()
                imageView.load(from: media.formatted?.medium ?? media.origin, withLoader: true, completion: {})
                imageViews.append(imageView)
            case .localVideo(let url):
                let imageView = createImageWithButton(url, thumbnail: nil)
                imageViews.append(imageView)
            case .remoteVideo(let media):
                let imageView = createImageWithButton(media.origin, thumbnail: media.formatted?.thumbnail)
                imageViews.append(imageView)
            case .remoteAudio, .localAudio:
                let audioView = RemovableAudioView()
                audioView.url = mediaType.audioURL
                audioView.delegate = self
                audioStackView.addArrangedSubview(audioView)
                audioCount += 1
            }
        }

        configureScrollViewSubviews(pagesCount: imageViews.count, views: imageViews)
        audioListView.isHidden = audioCount == 0
        addAudioView.isHidden = audioCount == 10
        updateUI()
    }
}

// MARK: - Form procession

private extension PostFormViewController {
    func formIsValid() -> Bool {
        var valid = true
        let validation = ValidationManager()
        
        [addressTextField, priceTextField, eventNameTextField, startDateTextField, endDateTextField].forEach( {$0?.error = nil} )
        
        if let validationError = validation
            .validatePostDescription(value: descriptionTextView.textIsEmpty ? nil : descriptionTextView.text)
            .errorMessage(field: descriptionTextView.title ?? "") {
            descriptionTextView.error = validationError.capitalizingFirstLetter()
            valid = false
        } else {
            descriptionTextView.error = nil
        }
        
        if viewModel.type == .crime || viewModel.type == .event {
            if let validationError = validation
                .validateRequired(value: addressTextField.text)
                .errorMessage(field: R.string.localizable.addressTitle()) {
                addressTextField.error = validationError.capitalizingFirstLetter()
                valid = false
            }
        }
        
        if viewModel.type == .offer {
            if let validationError = validation
                .validatePrice(value: priceTextField.text)
                .errorMessage(field: priceTextField.title ?? "") {
                priceTextField.error = validationError.capitalizingFirstLetter()
                valid = false
            }
        }
        
        if viewModel.type == .event {
            if let validationError = validation
                .validateEventName(value: eventNameTextField.text)
                .errorMessage(field: eventNameTextField.title ?? "") {
                eventNameTextField.error = validationError.capitalizingFirstLetter()
                valid = false
            }

            if let startDate = viewModel.selectedStartDate, startDate < Date() {
                startDateTextField.error = ValidationErrors().dateInThePast(field: R.string.localizable.startDateTitle())
                valid = false
            }

            if let endDate = viewModel.selectedEndDate, endDate < Date() {
                endDateTextField.error = ValidationErrors().dateInThePast(field: R.string.localizable.endTimeTitle())
                valid = false
            } else if let endDate = viewModel.selectedEndDate, let startDate = viewModel.selectedStartDate, endDate < startDate {
                endDateTextField.error = ValidationErrors().wrongEndEventDate(field: R.string.localizable.endTimeTitle(), startEventDate: startDateTextField?.text ?? "")
                valid = false
            }
        }
        
        return valid
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
        switch viewModel.type {
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

    func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField {
        case eventNameTextField:
            viewModel.setEventName(textField.text ?? "")
        case priceTextField:
            viewModel.setPrice(textField.text ?? "")
        default:
            break
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
        viewModel.setPlace(place)
        resultsController.dismiss(animated: true, completion: nil)
    }
}

// MARK: - UITextViewDelegate
extension PostFormViewController: UITextViewDelegate {
    
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

// MARK: - AvatarEditViewControllerDelegate
extension PostFormViewController: AvatarEditViewControllerDelegate {
    func avatarComplete(originalImage: UIImage, croppedImage: UIImage, crop: CGRect) {
        viewModel.updateCrop(croppedImage: croppedImage, uploadData: UploadImageData(image: originalImage, crop: .init(cgRect: crop)), at: currentMediaIndex)
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
            MyPostsRouter(in: navigationController).openAvatarEdit(image: compressedImage, delegate: self)
        case .video(let url):
            let videoLength = NSData(contentsOf: url)?.length ?? 0

            if videoLength > GlobalConstants.Limits.videoFileLimit {
                Toast.show(message: R.string.localizable.bigVideoFileError())
            } else {
                viewModel.addVideo(url: url)
            }
        default:
            break
        }
    }
}

// MARK: - HashtagsTextViewDelegate

extension PostFormViewController: HashtagsTextViewDelegate {
    func hashtagsListToggle(isShown: Bool) {
        nonHashtagsView.isHidden = isShown
        if viewModel.type == .event {
            eventNameTextField.isHidden = isShown
        }
    }

    func editingEnded() {
        viewModel.setDescription(descriptionTextView.textIsEmpty ? "" : descriptionTextView.textWithMentions)
    }
}

// MARK: - UIDocumentPickerDelegate

extension PostFormViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let existsAudioCount = viewModel.mediaToDisplay.filter { (media) -> Bool in
            switch media {
            case .localAudio, .remoteAudio:
                return true
            default:
                return false
            }
        }.count
        for url in urls.prefix(10 - existsAudioCount) {
            do {
                let resources = try url.resourceValues(forKeys: [.fileSizeKey])
                guard let fileSize = resources.fileSize, fileSize < Defaults.maxAudioFileSize else {
                    Toast.show(message: Alert.ErrorMessage.audioTooBig)
                    return
                }
            } catch {
                return
            }
            viewModel.addLocalAudio(url: url)
        }
    }
}


// MARK: -

extension PostFormViewController: RemovableAudioViewDelegate {
    func audioRemoved(url: URL) {
        viewModel.removeAudio(url: url)
    }
}


extension PostFormViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) {
            if let image = info[.originalImage] as? UIImage {
                self.viewModel.addCroppedImage(image: image)
            } else if let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
                self.viewModel.addVideo(url: url)
            }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
