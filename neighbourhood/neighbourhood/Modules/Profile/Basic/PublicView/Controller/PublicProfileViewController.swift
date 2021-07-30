//
//  ProfileViewController.swift
//  neighbourhood
//
//  Created by Dioksa on 24.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import TagListView

final class PublicProfileViewController: BaseViewController {
    @IBOutlet private weak var userNameLabel: UILabel!
    @IBOutlet private weak var arrdessLabel: UILabel!
    @IBOutlet private weak var userBirthLabel: UILabel!
    @IBOutlet private weak var userGenderLabel: UILabel!
    @IBOutlet private weak var birthdayIcon: UIImageView!
    
    @IBOutlet weak var avatarView: AvatarView!
    @IBOutlet weak var pagingView: PagingView!
    @IBOutlet weak var birthdayView: UIStackView!

    @IBOutlet private weak var messageButton: DarkButton!
    @IBOutlet private weak var followButton: UIButton!

    private var pageViews: [ProfileDetailsSection : UIView] = [:]
    private var viewModel = PublicProfileControllerViewModel()
    private lazy var profileManager: RestProfileManager = RestService.shared.createOperationsManager(from: self, type: RestProfileManager.self)
    var imagesView: PhotoGridView? { pageViews[.images] as? PhotoGridView }
    var interestsView: PublicInterestsView? { pageViews[.publicInterests] as? PublicInterestsView }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configurePagingView()
        viewModel.fetchProfileData()
        viewModel.loadAlbum()
    }
    
    // MARK: - Internal API
    func setupProfile(with id: Int) {
        viewModel.profileId = id
    }

    @IBAction func didTapFollow(_ sender: Any) {
        viewModel.toggleFollow()
    }
}

// MARK: - Private actions
private extension PublicProfileViewController {
    @IBAction func backButtonDidTap(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction private func reportButtonDidTap(_ sender: UIButton) {
        guard let profile = viewModel.profile else {
            return
        }
        let controller = EntityMenuController<PublicProfileModel>(entity: profile)
        controller.onMenuSelected = { [weak self] (type, profile) in
            guard let self = self else {
                return
            }
            switch type {
            case .report:
                BasicProfileRouter(in: self.navigationController).openReportViewController(for: profile)
            case .removeFollower:
                self.viewModel.removeFollower()
            default:
                break
            }

        }
        present(controller.alertController, animated: true)
    }
    
    
    @IBAction func messageButtonDidTap(_ sender: UIButton) {
        if let chatProfile = viewModel.chatProfile() {
            ChatRouter(in: navigationController).opeChatDetailsViewController(with: chatProfile)
        }
    }
}

// MARK: - Configurations
private extension PublicProfileViewController {
    func configurePagingView() {
        pageViews = viewModel.configurePagingView(pagingView, delegatedBy: self)
        imagesView?.withAdd = false
    }
    
    func bindViewModel() {
        viewModel.$profile.bind { [weak self] (profile) in
            self?.configureUI(with: profile)
        }
        viewModel.$mediaPosts.bind { [weak self] (_) in
            self?.updateAlbum()
        }
        viewModel.$error.bind { [weak self] (error) in
            if let error = error {
                self?.handleError(error)
            }
        }
    }
    
    func updateAlbum() {
        guard !viewModel.albumImages.isEmpty else {
            return
        }
        if imagesView == nil {
            pageViews[.images] = viewModel.configureImagesView(in: pagingView, delegatedBy: self)
            imagesView?.withAdd = false
        }
        imagesView?.setImages(viewModel.albumImages)
    }
    
    func configureUI(with profile: PublicProfileModel?) {
        guard let profile = profile else {
            return
        }
        userNameLabel.text = profile.fullName
        userGenderLabel.text = profile.genderString
        userNameLabel.text = profile.fullName
        birthdayView.isHidden = profile.birthday == nil
        userBirthLabel.text = profile.birthday?.fullDateString
        arrdessLabel.text = profile.address
        
        avatarView.updateWith(imageURL: profile.avatar?.formatted?.medium, fullName: profile.fullName)
        interestsView?.configure(with: profile)

        followButton.setTitle(profile.isFollowed ? "Following" : profile.isFollower ? "Follow Back" : "Follow" , for: .normal)
        followButton.backgroundColor = profile.isFollowed ? .clear : R.color.blueButton()
        followButton.borderWidth = profile.isFollowed ? 1 : 0
        followButton.setTitleColor(profile.isFollowed ? R.color.greyLight() : .white, for: .normal)
    }
}

// MARK: - PhotoGridViewDelegate

extension PublicProfileViewController: PhotoGridViewDelegate {
    func photoGridNewPhotoPressed() { }
    
    func photoGridRemovePressed(image: ImageModel) { }
    
    func photoGridImageSelected(image: ImageModel) {
        guard let index = viewModel.albumImages.firstIndex(where: {$0.id == image.id}),
              let profile = viewModel.profile else {
            return
        }
        BasicProfileRouter(in: navigationController).openAlbumList(profile: profile.selectorProfile, loadedPosts: viewModel.mediaPosts, selectedPostIndex: index)
    }
    
    func photoGridWillShowLastLine() {
        viewModel.loadAlbum()
    }
}
