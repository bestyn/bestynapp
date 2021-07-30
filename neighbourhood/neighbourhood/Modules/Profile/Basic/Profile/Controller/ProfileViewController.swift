//
//  ProfileViewController.swift
//  neighbourhood
//
//  Created by Dioksa on 24.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import Floaty

final class ProfileViewController: BaseViewController {
    @IBOutlet private weak var userNameLabel: UILabel!
    @IBOutlet private weak var arrdessLabel: UILabel!
    @IBOutlet private weak var userBirthLabel: UILabel!
    @IBOutlet private weak var userGenderLabel: UILabel!
    @IBOutlet private weak var birthdayIcon: UIImageView!
    @IBOutlet private weak var profileSettingsButton: UIButton!
    @IBOutlet weak var birthdayView: UIStackView!
    @IBOutlet weak var followersCountLabel: UILabel!
    @IBOutlet weak var followedCountLabel: UILabel!

    @IBOutlet weak var pagingView: PagingView!

    @IBOutlet weak var avatarView: AvatarView!
    @IBOutlet private weak var spinner: UIActivityIndicatorView!

    private var pageViews: [ProfileDetailsSection : UIView] = [:]
    
    private var scrollViewSetUp = false

    private let scrollHelper = PageScrollingHelper()
    private let viewModel = ProfileControllerViewModel()
    private lazy var mediaProcessor: MediaProcessor = MediaProcessor(viewController: self, delegate: self)
    private lazy var profileManager: RestProfileManager = RestService.shared.createOperationsManager(from: self, type: RestProfileManager.self)
    private lazy var authorizationManager: RestAuthorizationManager = RestService.shared.createOperationsManager(from: self, type: RestAuthorizationManager.self)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
        configureTexts()
        configurePagingView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.fetchUserProfile()
        viewModel.refresh()
    }
    
    // MARK: - Private actions

    @IBAction func profileSettingsButtonDidTap(_ sender: UIButton) {
        BasicProfileRouter(in: navigationController).openProfileSettingsViewController()
    }

    @IBAction func didTapFollowers(_ sender: Any) {
        if viewModel.profile?.followersCount == 0 {
            return
        }
        FollowRouter(in: navigationController).openFollowers()
    }

    @IBAction func didTapFollowed(_ sender: Any) {
        if viewModel.profile?.followingCount == 0 {
            return
        }
        FollowRouter(in: navigationController).openFollowed()
    }

    func defineElementsVisibility() {
        guard let currentProfile = viewModel.profile else {
            return
        }
        let imageURL = currentProfile.avatar?.formatted?.medium
        avatarView.updateWith(imageURL: imageURL, fullName: currentProfile.fullName)
    }
}

// MARK: - Configurations
private extension ProfileViewController {
    private func configureTexts() {
        profileSettingsButton.setTitle(R.string.localizable.profileSettingsButtonTitle(), for: .normal)
    }

    private func configurePagingView() {
        pageViews = viewModel.configurePagingView(pagingView, delegatedBy: self)
    }
}

//MARK: - Supporting data methods
private extension ProfileViewController {

    func updateStoredUser(with profile: UserProfileModel) {
        var user = ArchiveService.shared.userModel
        user?.profile = profile
        ArchiveService.shared.userModel = user
        ArchiveService.shared.seeBusinessContent = profile.seeBusinessPosts
        ArchiveService.shared.currentProfile = profile.selectorProfile
    }

    func updateProfileInfo(_ profile: UserProfileModel) {
        userGenderLabel.text = profile.genderString
        userNameLabel.text = profile.fullName
        birthdayView.isHidden = profile.birthday == nil
        userBirthLabel.text = profile.birthday?.fullDateString
        arrdessLabel.text = profile.address
        (pageViews[.interests] as? MyInterestsView)?.hashtags = profile.hashtags
        let imageURL = profile.avatar?.formatted?.medium
        avatarView.updateWith(imageURL: imageURL, fullName: profile.fullName)
        followersCountLabel.text = "\(profile.followersCount)"
        followedCountLabel.text = "\(profile.followingCount)"
        followersCountLabel.textColor = profile.followersCount == 0 ? R.color.darkGrey() : R.color.mainBlack()
        followedCountLabel.textColor = profile.followingCount == 0 ? R.color.darkGrey() : R.color.mainBlack()
    }
    
    func updateAlbum() {
        (pageViews[.images] as? PhotoGridView)?.setImages(viewModel.albumImages)
    }
    
    func addImageToAlbum(_ image: ImageModel?) {
        if let image = image {
            (pageViews[.images] as? PhotoGridView)?.imageUploadingCompleted(with: image)
        }
    }
    
    func bindViewModel() {
        viewModel.$profile.bind { [weak self] (profile) in
            if let profile = profile {
                self?.updateProfileInfo(profile)
            }
        }
        viewModel.$error.bind { [weak self] (error) in
            if let error = error {
                self?.handleError(error)
            }
        }

        viewModel.$isLoading.bind { [weak self] (isLoading) in
            isLoading ? self?.spinner.startAnimating() : self?.spinner.stopAnimating()
        }

        viewModel.$mediaPosts.bind { [weak self] (_) in
            self?.updateAlbum()
        }
    }
}

// MARK: - MyInterestsViewDelegate
extension ProfileViewController: MyInterestsViewDelegate {
    func openMyInterestsScreen() {
        BasicProfileRouter(in: navigationController).openMyInterestsViewController(type: .edit)
    }
}

// MARK: - PhotoGridViewDelegate
extension ProfileViewController: PhotoGridViewDelegate {
    func photoGridNewPhotoPressed() {
        mediaProcessor.openMediaOptions([
            .gallery(),
            .capture()
        ])
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
        guard let index = viewModel.albumImages.firstIndex(where: {image.id == $0.id}),
              let currentProfile = viewModel.profile else {
            return
        }
        BasicProfileRouter(in: navigationController).openAlbumList(profile: currentProfile.selectorProfile, loadedPosts: viewModel.mediaPosts, selectedPostIndex: index)
    }
    
    func photoGridWillShowLastLine() {
        viewModel.loadMore()
    }
}

// MARK: - MediaProcessing
extension ProfileViewController: MediaProcessorDelegate {
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
extension ProfileViewController: AvatarEditViewControllerDelegate {
    func avatarComplete(originalImage: UIImage, croppedImage: UIImage, crop: CGRect) {
        guard let compressedImage = originalImage.compress(maxSizeMB: 5) else {
            return
        }
        let scaleValue = compressedImage.size.width / originalImage.size.width
        viewModel.uploadImage(compressedImage, crop: crop.scale(scaleValue))
        (pageViews[.images] as? PhotoGridView)?.imageUploadingStarted()
    }
}
