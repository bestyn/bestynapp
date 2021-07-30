//
//  ProfileSettingsViewController.swift
//  neighbourhood
//
//  Created by Dioksa on 06.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import GBKSoftTextField
import GoogleMaps
import GooglePlaces

final class ProfileSettingsViewController: BaseViewController, EmailVerification {    
    @IBOutlet private weak var profileInfoHeader: SettingsHeaderView!
    @IBOutlet private weak var profileInfoView: SettingsProfileInfoView!
    
    @IBOutlet private weak var changeEmailHeader: SettingsHeaderView!
    @IBOutlet private weak var changeEmailView: SettingsChangeEmailView!
    
    @IBOutlet private weak var changePasswordHeader: SettingsHeaderView!
    @IBOutlet private weak var changePasswordView: SettingsChangePasswordView!
    
    @IBOutlet private weak var businessContentView: UIView!
    @IBOutlet private weak var showBusinessContentLabel: UILabel!
    @IBOutlet private weak var switcher: UISwitch!
    
    private var userProfile: UserModel? {
        didSet { fillData() }
    }
    
    private lazy var profileManager: RestProfileManager = RestService.shared.createOperationsManager(from: self, type: RestProfileManager.self)
    private lazy var mediaProcessor: MediaProcessor = MediaProcessor(viewController: self, delegate: self)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchCurrentUser()
        setTexts()
        changeEmailView.delegate = self
        changePasswordView.delegate = self
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        gesture.numberOfTapsRequired = 1
        businessContentView.addGestureRecognizer(gesture)
    }

    @IBAction private func backButtonDidTap(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Private actions
    @IBAction private func switchDidTap(_ sender: UISwitch) {
        switcher.thumbTintColor = switcher.isOn ? R.color.blueButton() : R.color.greyMedium()

        let updateData = UpdateProfileData(seeBusinessPosts: switcher.isOn)
        restUpdateProfile(data: updateData)
    }
    
    @objc private func viewTapped() {
        [profileInfoHeader, changeEmailHeader, changePasswordHeader].forEach { $0?.open = false }
        self.profileInfoView.isHidden = true
        self.changeEmailView.isHidden = true
        self.changePasswordView.isHidden = true
    }

    private func updateStoredUser(with user: UserModel) {
        ArchiveService.shared.userModel = user
        ArchiveService.shared.seeBusinessContent = user.profile.seeBusinessPosts
        userProfile = user
        switcher.isOn = user.profile.seeBusinessPosts
        switcher.thumbTintColor = user.profile.seeBusinessPosts ? R.color.blueButton() : R.color.greyMedium()
    }
}

// MARK: - REST requests
private extension ProfileSettingsViewController {
    func fetchCurrentUser() {
        profileManager.getUser()
            .onComplete { [weak self] (response) in
                if let user = response.result {
                    self?.updateStoredUser(with: user)
                }
        } .onError { [weak self] (error) in
            self?.handleError(error)
        } .run()
    }
    
    func restUpdateProfile(data: UpdateProfileData) {
        profileManager.changeUserProfile(data: data)
            .onComplete { [weak self] (response) in
                Toast.show(message: R.string.localizable.successfullyUpdatedProfile())
                self?.fetchCurrentUser()
        } .onError { [weak self] (error) in
            self?.handleError(error)
        } .run()
    }
}

// MARK: - Text Configurations
private extension ProfileSettingsViewController {
    func setTexts() {
        profileInfoHeader.title = R.string.localizable.editProfileTitle()
        changeEmailHeader.title = R.string.localizable.changeEmailTitle()
        changePasswordHeader.title = R.string.localizable.changePasswordButtonTitle()
    }
    
    func fillData() {
        profileInfoView.user = userProfile
        changeEmailView.email = userProfile?.email
    }
}

// MARK: - UISearchBarDelegate
extension ProfileSettingsViewController: SettingsProfileInfoViewDelegate {
    func goToBasicProfile() {
        navigationController?.popViewController(animated: true)
    }
    
    func profileInfoViewPresenter() -> UIViewController {
        return self
    }
    
    func profileInfoViewChangeImage() {
        var options: [MediaProcessingOption] = [.gallery(), .capture()]
        if userProfile?.profile.avatar != nil {
            options.append(.remove())
        }
        mediaProcessor.openMediaOptions(options)
    }
}

// MARK: - SettingsHeaderViewDelegate
extension ProfileSettingsViewController: SettingsHeaderViewDelegate {
    func settingsHeaderDidTap(headerView: SettingsHeaderView) {
        [profileInfoHeader, changeEmailHeader, changePasswordHeader].filter({$0 != headerView}).forEach({$0?.open = false})
        headerView.open.toggle()
        profileInfoView.isHidden = !self.profileInfoHeader.open
        changeEmailView.isHidden = !self.changeEmailHeader.open
        changePasswordView.isHidden = !self.changePasswordHeader.open
    }
}

// MARK: - SettingsChangeEmailViewDelegate
extension ProfileSettingsViewController: SettingsChangeEmailViewDelegate {
    func changeEmailView(didChange email: String) {
        guard ValidationManager().checkInternetConnection() else {
            Toast.show(message: R.string.localizable.internetConnectionError())
            return
        }
        
        ArchiveService.shared.newEmail = email
        showEmailVerificationMessage(email: email, title: Alert.Title.changeEmail, message: Alert.Message.changeEmail)
    }
}

// MARK: - SettingsChangePasswordViewDelegate
extension ProfileSettingsViewController: SettingsChangePasswordViewDelegate {
    func goToBasicProfilePage() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - MediaProcessing
extension ProfileSettingsViewController: MediaProcessorDelegate {
    func mediaOptionProcessed(result: MediaProcessingResult) {
        switch result {
        case .image(let image, _):
            profileInfoView.updatedImage = image
        case .remove:
            profileInfoView.needRemoveAvatar = true
        default:
            break
        }
    }
}
