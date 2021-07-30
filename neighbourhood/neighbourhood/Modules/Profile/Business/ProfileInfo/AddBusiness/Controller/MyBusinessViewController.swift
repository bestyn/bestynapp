//
//  MyBusinessViewController.swift
//  neighbourhood
//
//  Created by Dioksa on 24.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

final class MyBusinessViewController: BaseViewController, AvatarChanging {
    var imagePicker: UIImagePickerController = UIImagePickerController()
    
    @IBOutlet private weak var userLogoImageView: UIImageView!
    @IBOutlet private weak var profileNameLabel: UILabel!
    @IBOutlet private weak var userMiniLogoImageView: UIImageView!
    @IBOutlet private weak var logoutButton: UIButton!
    @IBOutlet private weak var profileSettingsButton: DarkButton!
    @IBOutlet private weak var paymentPlansButton: LightButton!
    
    @IBOutlet private weak var scrollView: UIScrollView!
    
    @IBOutlet private weak var profileInfoButton: UIButton!
    @IBOutlet private weak var businessImagesButton: UIButton!
    
    @IBOutlet private weak var profileInfoBottomView: UIView!
    @IBOutlet private weak var businessImagesBottomView: UIView!
    
    @IBOutlet private weak var spinner: UIActivityIndicatorView!
    
    // TODO: - remove after test
    @IBOutlet private weak var profileIdTextField: UITextField!
    
    private let profileView = BusinessProfileInfoView()
    private let photosView = BusinessPhotoView()
    private var scrollViewSetUp = false
    
    private lazy var views = [profileView, photosView]
    
    var currentProfile: BusinessProfile?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
        
        photosView.imageDelegate = self
        imagePicker.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureImageViews()
        scrollView.layoutIfNeeded()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !scrollViewSetUp {
            createScrollPages()
        }
    }
    
    override var isNavigationBarVisible: Bool {
        return false
    }
    
    private func defineElementsVisibility(avatar: UserAvatar?) {
        if let imageURL = avatar?.origin {
            userMiniLogoImageView.load(from: imageURL) { }
            userLogoImageView.load(from: imageURL) {
                self.spinner.stopAnimating()
            }
        } else {
            userMiniLogoImageView.image = nil
            userLogoImageView.image = nil
            spinner.stopAnimating()
        }
        
        userMiniLogoImageView.isHidden = avatar == nil
        userLogoImageView.isHidden = avatar == nil
    }
    
    func removeAvatar() { }
    
    // MARK: - Scroll configurations
    private func createScrollPages() {
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        
        let numberOfPages = 2
        let viewWidth = scrollView.frame.size.width
        let viewHeight = scrollView.frame.size.height
        
        var x : CGFloat = 0
        var maxHeight: CGFloat = viewHeight
        
        for i in 0...(numberOfPages - 1) {
            let view = views[i]
            let size = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            maxHeight = max(maxHeight, size.height)
        }
        
        for i in 0...(numberOfPages - 1) {
            let view = views[i]
            view.frame = CGRect(x: x, y: 0, width: viewWidth, height: maxHeight)
            scrollView.addSubview(view)
            x = view.frame.origin.x + viewWidth
        }
        
        scrollView.contentSize = CGSize(width: x, height: scrollView.frame.size.height)
        scrollView.heightAnchor.constraint(equalToConstant: maxHeight).isActive = true
        scrollViewSetUp = true
    }
    
    private func scrollToPage(_ page: Int) {
        let offset = CGFloat(page) * scrollView.frame.size.width
        scrollView.setContentOffset(CGPoint(x: offset, y: 0) , animated: true)
    }
    
    private func setSelectedButton(for page: Int) {
        setDefaultColors(bottomView: businessImagesBottomView, button: businessImagesButton)
        setDefaultColors(bottomView: profileInfoBottomView, button: profileInfoButton)
        
        switch page {
        case 0:
            setActiveColors(bottomView: profileInfoBottomView, button: profileInfoButton)
        case 1:
            setActiveColors(bottomView: businessImagesBottomView, button: businessImagesButton)
        default:
            break
        }
    }
    
    private func setActiveColors(bottomView: UIView, button: UIButton) {
        bottomView.backgroundColor = R.color.accentBlue()
        button.setTitleColor(R.color.accentBlue(), for: .normal)
    }
    
    private func setDefaultColors(bottomView: UIView, button: UIButton) {
        bottomView.backgroundColor = R.color.greyBackground()
        button.setTitleColor(R.color.greyMedium(), for: .normal)
    }
    
    // MARK: - Private actions
    @IBAction func showPublicProfile(_ sender: UIButton) {
        BusinessProfileRouter(in: navigationController).openPublicProfileController(id: Int(profileIdTextField.text ?? "") ?? 10)
    }
    
    @IBAction private func dropDownButtonDidTap(_ sender: UIButton) {
        BasicProfileRouter(in: navigationController).openProfileSwitcherController(delegate: self)
    }
    
    @IBAction private func logoutButtonDidTap(_ sender: UIButton) {
        signOut()
    }
    
    @IBAction private func profileInfoButtonDidTap(_ sender: UIButton) {
        setSelectedButton(for: 0)
        scrollToPage(0)
    }
    
    @IBAction private func myInterestsButtonDidTap(_ sender: UIButton) {
        setSelectedButton(for: 1)
        scrollToPage(1)
    }
    
    @IBAction func profileSettingsButtonDidTap(_ sender: UIButton) {
        BusinessProfileRouter(in: self.navigationController).openAddBusinessProfileViewController(screenType: .edit, businessProfile: currentProfile, profileDelegate: self)
    }
    
    @IBAction func paymentPlansButtonDidTap(_ sender: UIButton) {
        BusinessProfileRouter(in: navigationController).openPaymentPlansViewController()
    }
}

// MARK: - Configurations
private extension MyBusinessViewController {
    func configureImageViews() {
        userMiniLogoImageView.cornerRadius = userMiniLogoImageView.frame.height / 2
        userMiniLogoImageView.clipsToBounds = true
        userLogoImageView.cornerRadius = userLogoImageView.frame.height / 2
        userLogoImageView.clipsToBounds = true
    }
    
    func configureTexts() {
        profileSettingsButton.setTitle(R.string.localizable.profileSettingsButtonTitle(), for: .normal)
        paymentPlansButton.setTitle(R.string.localizable.paymentPlansButtonTitle(), for: .normal)
        profileInfoButton.setTitle(R.string.localizable.businessInformationTitle(), for: .normal)
        businessImagesButton.setTitle(R.string.localizable.businessImagesTitle(), for: .normal)
    }
    
    func updateUI() {
        configureTexts()
        profileNameLabel.text = currentProfile?.fullName
        profileView.updateProfileView(profile: currentProfile)
        defineElementsVisibility(avatar: currentProfile?.avatar)

        if let images = currentProfile?.images {
            photosView.showAllImages(images: images)
        }
    }
}

// MARK: - REST requests
private extension MyBusinessViewController {
    func signOut() {
        Alert(title: Alert.Title.signOut, message: Alert.Message.signOut)
            .configure(doneText: Alert.Action.signOut)
            .configure(cancelText: Alert.Action.no)
            .show { (result) in
                if result == .done {
                    self.restSignOut()
                }
        }
    }
    
    func restSignOut() {
        RestAuthorization(requestIdentifier: name).signOut { _ in
            RootRouter.shared.exitApp()
        }
    }
    
    private func saveImageToServer(image: UIImage?) {
        guard let id = currentProfile?.id, let image = image else {
            assertionFailure("🔥 Check business Id or new user image at MyBusinessViewController")
            return
        }
        
        RestBusinessProfile(requestIdentifier: name).addBusinessProfileImages(profileId: id, image: image) { [weak self] (result) in
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let model):
                UserDefaults.standard.set(id, forKey: "currentId")
                self.photosView.saveNew(image: model.0)
            case .failure(let error):
                self.handleError(error)
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

// MARK: - StaticTextDelegate
extension MyBusinessViewController: StaticTextDelegate {
    func showText(for page: PageType) {
        switch page {
        case .policy:
            SupportRouter(in: navigationController).openPage(type: .policy)
        case .terms:
            SupportRouter(in: navigationController).openPage(type: .terms)
        case .about:
            SupportRouter(in: navigationController).openPage(type: .about)
        }
    }
}

// MARK: - AccountSwitcherDelegate
extension MyBusinessViewController: AccountSwitcherDelegate {
    func switchToProfile(addProfile: Bool, business: BusinessProfile?) {
        if addProfile {
            BusinessProfileRouter(in: self.navigationController).openAddBusinessProfileViewController(screenType: .add)
        } else if business != nil {
            (tabBarController as? MainScreenViewController)?.switchTo(type: .business, business: business)
        } else {
            (tabBarController as? MainScreenViewController)?.switchTo(type: .basic, business: nil)
        }
    }
}

// MARK: - BusinessPhotoViewDelegate
extension MyBusinessViewController: BusinessPhotoViewDelegate {
    func addNewBusinessImage() {
        changeAvatar(needsToRemove: false)
    }
    
    func removeBusinessImage(id: Int) {
        RestBusinessProfile(requestIdentifier: name).deleteBusinessProfileImages(mediaId: id) { (result) in
            switch result {
            case .success(_):
                Toast.show(message: "Image has been removed")
            case .failure(let error):
                self.handleError(error)
            }
        }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension MyBusinessViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            return
        }
    
        saveImageToServer(image: image)
        imagePicker.dismiss(animated: true, completion: nil)
    }
}

// MARK: - BusinessProfileUpdatableDelegate
extension MyBusinessViewController: BusinessProfileUpdatableDelegate {
    func updateProfile(with profile: BusinessProfile?) {
        currentProfile = profile
        updateUI()
    }
}
