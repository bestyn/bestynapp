//
//  PublicBusinessViewController.swift
//  neighbourhood
//
//  Created by Dioksa on 24.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import TagListView

final class PublicBusinessViewController: BaseViewController {
    
    // MARK: - Internal properties
    var currentProfileId: Int? {
        return viewModel.currentProfile?.id
    }
    
    // MARK: - Private UI properties
    @IBOutlet private weak var profileNameLabel: UILabel!
    @IBOutlet private weak var messageButton: UIButton!
    @IBOutlet private weak var followButton: UIButton!
    @IBOutlet private weak var profileDescriptionLabel: UILabel!
    @IBOutlet private weak var interestsView: TagListView!
    @IBOutlet weak var informationHolderView: UIView!
    @IBOutlet weak var avatarView: AvatarView!

    private let profileView = BusinessProfileInfoView(needsToShowHouse: false)
    private let photosView = PhotoGridView()
    private lazy var views: [(String, UIView)] = [(R.string.localizable.businessInformationTitle(), profileView)] {
        didSet { updateInfoViews() }
    }
    
    // MARK: - Private properties
    private var scrollViewSetUp = false
    private let scrollHelper = PageScrollingHelper()
    
    private var viewModel = PublicBusinessControllerViewModel()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
        viewModel.fetchProfile()
        viewModel.loadAlbum()
        setupViews()
        updateInfoViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    //MARK: - Internal API
    func setupProfile(with id: Int) {
        viewModel.businessId = id
    }

    @IBAction func didTapFollow(_ sender: UIButton) {
        viewModel.toggleFollow()
    }
}


// MARK: - Private actions

private extension PublicBusinessViewController {
    @IBAction func backButtonDidTap(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func reportButtonDidTap(_ sender: UIButton) {
        guard let profile = viewModel.currentProfile else {
            return
        }
        let controller = EntityMenuController(entity: profile)
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
        guard let profile = viewModel.currentProfile else {
            return
        }
        ChatRouter(in: navigationController).opeChatDetailsViewController(with: profile.chatProfile)
    }

    private func updateInfoViews() {
        if views.count == 1 {
            let titleView = UIView()
            let label = UILabel()
            label.textColor = R.color.mainBlack()
            label.font = R.font.poppinsMedium(size: 14)
            label.text = views.first?.0
            titleView.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: titleView.topAnchor, constant: 20),
                label.bottomAnchor.constraint(equalTo: titleView.bottomAnchor),
                label.leadingAnchor.constraint(equalTo: titleView.leadingAnchor, constant: 20),
                label.trailingAnchor.constraint(equalTo: titleView.trailingAnchor, constant: -20)
            ])
            let stackView = UIStackView(arrangedSubviews: [titleView, views.first!.1])
            stackView.spacing = 20
            stackView.axis = .vertical
            replaceInfoView(stackView)
        } else {
            let pagingView = PagingView()
            pagingView.views = views.map({ (title, view) -> PagingView.PagingChildView in
                return .init(buttonTitle: title, view: view)
            })
            replaceInfoView(pagingView)
        }
    }

    private func replaceInfoView(_ view: UIView) {
        informationHolderView.subviews.first?.removeFromSuperview()
        informationHolderView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: informationHolderView.topAnchor),
            view.bottomAnchor.constraint(equalTo: informationHolderView.bottomAnchor),
            view.leadingAnchor.constraint(equalTo: informationHolderView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: informationHolderView.trailingAnchor)
        ])
    }
}

// MARK: - Configurations

private extension PublicBusinessViewController {
    func updateUI() {
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

        followButton.setTitle(profile.isFollowed ? "Following" : profile.isFollower ? "Follow Back" : "Follow" , for: .normal)
        followButton.backgroundColor = profile.isFollowed ? .clear : R.color.blueButton()
        followButton.borderWidth = profile.isFollowed ? 1 : 0
        followButton.setTitleColor(profile.isFollowed ? R.color.greyLight() : .white, for: .normal)
    }
    
    func bindViewModel() {

        viewModel.$currentProfile.bind { [weak self] (profile) in
            self?.updateUI()
        }
        viewModel.$error.bind { (error) in
            if let error = error {
                self.handleError(error)
            }
        }
        viewModel.$mediaPosts.bind { (_) in
            self.updateAlbum()
        }
    }
    
    func updateAlbum() {
        guard !viewModel.mediaPosts.isEmpty else {
            return
        }
        if !views.contains(where: { $0.1 is PhotoGridView }) {
            views.append((R.string.localizable.businessImagesTitle(), photosView))
        }
        photosView.setImages(viewModel.mediaPosts.compactMap({ImageModel(post: $0)}))
    }
    
    func setupViews() {
        photosView.delegate = self
        photosView.withAdd = false
    }
}

// MARK: - PhotoGridViewDelegate

extension PublicBusinessViewController: PhotoGridViewDelegate {
    func photoGridNewPhotoPressed() {}
    
    func photoGridRemovePressed(image: ImageModel) {}
    
    func photoGridImageSelected(image: ImageModel) {
        guard let index = viewModel.mediaPosts.firstIndex(where: {image.id == $0.id}),
              let currentProfile = viewModel.currentProfile else {
            return
        }
        BasicProfileRouter(in: navigationController).openAlbumList(profile: currentProfile.selectorProfile, loadedPosts: viewModel.mediaPosts, selectedPostIndex: index)
    }
    
    func photoGridWillShowLastLine() {
        viewModel.loadAlbum()
    }
}

