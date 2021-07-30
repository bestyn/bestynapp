//
//  MyBusinessViewController.swift
//  neighbourhood
//
//  Created by Dioksa on 24.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import TagListView

final class MyBusinessViewController: BaseViewController {

    // MARK: - Internal properties
    var currentProfileId: Int? {
        return viewModel.currentProfile?.id
    }
    
    // MARK: - Private UI properties
    @IBOutlet private weak var profileNameLabel: UILabel!
    @IBOutlet private weak var profileDescriptionLabel: UILabel!
    @IBOutlet private weak var profileSettingsButton: UIButton!
    @IBOutlet private weak var interestsView: TagListView!
 //   @IBOutlet private weak var paymentPlansButton: WhiteButton!
    
    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var profileInfoButton: UIButton!
    @IBOutlet private weak var businessImagesButton: UIButton!
    
    @IBOutlet private weak var profileInfoBottomView: UIView!
    @IBOutlet private weak var businessImagesBottomView: UIView!

    @IBOutlet private weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var avatarView: AvatarView!

    @IBOutlet weak var followersCountLabel: UILabel!
    @IBOutlet weak var followedCountLabel: UILabel!


    private let profileView = BusinessProfileInfoView(needsToShowHouse: true)
    private let photosView = PhotoGridView()
    private lazy var views = [profileView, photosView]
    
    // MARK: - Private properties
    private let viewModel = MyBusinessControllerViewModel()
    
    private var scrollViewSetUp = false
    private let scrollHelper = PageScrollingHelper()

    private lazy var mediaProcessor: MediaProcessor = MediaProcessor(viewController: self, delegate: self)
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
        updateUI()
        photosView.delegate = self
        scrollView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scrollView.layoutIfNeeded()
        viewModel.fetchUserProfile()
        viewModel.refresh()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupPageViews()
    }
    
    // MARK: - Internal API
    func removeAvatar() { }
    
    func setupBusinessProfile(_ profile: BusinessProfile?) {
        viewModel.currentProfile = profile
    }
    
    // MARK: - Scroll configurations
    private func scrollToPage(_ page: Int) {
        let offset = CGFloat(page) * scrollView.frame.size.width
        scrollView.setContentOffset(CGPoint(x: offset, y: 0) , animated: true)
    }
    
    private func setSelectedButton(for page: Int) {
        scrollHelper.setDefaultColors(bottomView: businessImagesBottomView, button: businessImagesButton)
        scrollHelper.setDefaultColors(bottomView: profileInfoBottomView, button: profileInfoButton)
        
        switch page {
        case 0:
            scrollHelper.setActiveColors(bottomView: profileInfoBottomView, button: profileInfoButton)
        case 1:
            scrollHelper.setActiveColors(bottomView: businessImagesBottomView, button: businessImagesButton)
        default:
            break
        }
    }

    @IBAction func didTapFollowers(_ sender: Any) {
        if viewModel.currentProfile?.followersCount == 0 {
            return
        }
        FollowRouter(in: navigationController).openFollowers()
    }

    @IBAction func didTapFollowed(_ sender: Any) {
        if viewModel.currentProfile?.followingCount == 0 {
            return
        }
        FollowRouter(in: navigationController).openFollowed()
    }
}

// MARK: - Private actions
private extension MyBusinessViewController {
    @IBAction func logoutButtonDidTap(_ sender: UIButton) {
        signOut()
    }
    
    @IBAction func profileInfoButtonDidTap(_ sender: UIButton) {
        setSelectedButton(for: 0)
        scrollToPage(0)
    }
    
    @IBAction func myInterestsButtonDidTap(_ sender: UIButton) {
        setSelectedButton(for: 1)
        scrollToPage(1)
    }
    
    @IBAction func profileSettingsButtonDidTap(_ sender: UIButton) {
        guard let currentProfile = viewModel.currentProfile else {
            return
        }
        BusinessProfileRouter(in: self.navigationController).openEditBusinessProfile(profile: currentProfile)
    }
    
    @IBAction func paymentPlansButtonDidTap(_ sender: UIButton) {
        BusinessProfileRouter(in: navigationController).openPaymentPlansViewController()
    }
}

// MARK: - Configurations
private extension MyBusinessViewController {
    func configureTexts() {
        profileSettingsButton.setTitle(R.string.localizable.editProfileScreenTitle(), for: .normal)
        //paymentPlansButton.setTitle(R.string.localizable.paymentPlansButtonTitle(), for: .normal)
        profileInfoButton.setTitle(R.string.localizable.businessInformationTitle(), for: .normal)
        businessImagesButton.setTitle(R.string.localizable.businessImagesTitle(), for: .normal)
    }
    
    func updateUI() {
        configureTexts()
        guard let profile = viewModel.currentProfile else {
             return
        }
        profileNameLabel.text = profile.fullName
        profileDescriptionLabel.text = profile.description
        profileView.profile = profile
        avatarView.updateWith(imageURL: profile.avatar?.formatted?.medium, fullName: profile.fullName)
        if let font = R.font.poppinsMedium(size: 13) {
            interestsView.textFont = font
        }
        interestsView.removeAllTags()
        profile.hashtags.forEach {
            interestsView.addTag($0.name)
        }

        followersCountLabel.text = "\(profile.followersCount)"
        followedCountLabel.text = "\(profile.followingCount)"
        followersCountLabel.textColor = profile.followersCount == 0 ? R.color.darkGrey() : R.color.mainBlack()
        followedCountLabel.textColor = profile.followingCount == 0 ? R.color.darkGrey() : R.color.mainBlack()
    }
    
    func updateAlbum() {
        photosView.setImages(viewModel.albumImages)
    }
    
    func addImageToAlbum(_ image: ImageModel?) {
        if let image = image {
            photosView.imageUploadingCompleted(with: image)
        }
    }
    
    func setupPageViews() {
        if !scrollViewSetUp || scrollView.bounds.width != view.bounds.width {
            scrollHelper.createScrollPages(scrollView: scrollView, views: views) { [weak self] (result) in
                guard let strongSelf = self else { return }
                strongSelf.scrollViewSetUp = result
            }
        }
    }
}

// MARK: - Supporting methods
private extension MyBusinessViewController {
    func signOut() {
        Alert(title: Alert.Title.signOut, message: Alert.Message.signOut)
            .configure(doneText: Alert.Action.signOut)
            .configure(cancelText: Alert.Action.no)
            .show { (result) in
                if result == .done {
                    self.viewModel.signOut()
                }
        }
    }
    
    func bindViewModel() {
        viewModel.bindLoadingState { [weak self] (state) in
            switch state {
            case .didNotStart:
                self?.spinner.stopAnimating()
            case .inProgress:
                self?.spinner.startAnimating()
            case .loadFinished:
                self?.spinner.stopAnimating()
            case .albumLoaded:
                self?.spinner.stopAnimating()
                self?.updateAlbum()
            case .imageUploadCompleted(let imageModel):
                self?.addImageToAlbum(imageModel)
            case .profileLoaded:
                self?.updateUI()
                self?.spinner.stopAnimating()
            case .loadFailed(let error):
                self?.spinner.stopAnimating()
                self?.handleError(error)
            case .imageUploadFailed(let error):
                self?.spinner.stopAnimating()
                self?.photosView.imageUploadingFailed()
                self?.handleError(error)
            }
        }
    }
}

// MARK: - UIScrollViewDelegate
extension MyBusinessViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        setSelectedButton(for: page)
    }
}

// MARK: - BusinessProfileUpdatableDelegate
extension MyBusinessViewController: BusinessProfileUpdatableDelegate {
    func updateBottomBar(with profile: BusinessProfile?) {
    }
    
    func updateProfile(with profile: BusinessProfile?) {
        viewModel.currentProfile = profile
        ArchiveService.shared.currentProfile = profile?.selectorProfile
        //profileSelectorView.update()
        updateUI()
    }
}

// MARK: - MediaProcessing
extension MyBusinessViewController: MediaProcessorDelegate {
    func mediaOptionProcessed(result: MediaProcessingResult) {
        switch result {
        case .image(let image, _):
            MyPostsRouter(in: navigationController).openAvatarEdit(image: image, delegate: self)
        default:
            break
        }
    }
}

// MARK: - AvatarEditViewControllerDelegate
extension MyBusinessViewController: AvatarEditViewControllerDelegate {
    func avatarComplete(originalImage: UIImage, croppedImage: UIImage, crop: CGRect) {
        guard let compressedImage = originalImage.compress(maxSizeMB: 5) else {
            return
        }
        let scaleValue = compressedImage.size.width / originalImage.size.width
        viewModel.uploadImage(compressedImage, crop: crop.scale(scaleValue))
        photosView.imageUploadingStarted()
    }
}

// MARK: - PhotoGridViewDelegate
extension MyBusinessViewController: PhotoGridViewDelegate {
    func photoGridNewPhotoPressed() {
        mediaProcessor.openMediaOptions([.gallery(), .capture()])
    }
    
    func photoGridRemovePressed(image: ImageModel) {
        Alert(message: R.string.localizable.deleteImageQuestion())
            .configure(doneText: R.string.localizable.deleteButtonTitle())
            .configure(cancelText: R.string.localizable.cancelTitle())
            .show { (result) in
                switch result {
                case .done:
                    self.viewModel.remove(image)
                default:
                    break
                }
            }
    }
    
    func photoGridImageSelected(image: ImageModel) {
        guard let index = viewModel.albumImages.firstIndex(where: {$0.id == image.id}),
              let profile = viewModel.currentProfile else {
            return
        }
        BasicProfileRouter(in: navigationController).openAlbumList(profile: profile.selectorProfile, loadedPosts: viewModel.mediaPosts, selectedPostIndex: index)
    }
    
    func photoGridWillShowLastLine() {
        viewModel.loadMore()
    }
}
