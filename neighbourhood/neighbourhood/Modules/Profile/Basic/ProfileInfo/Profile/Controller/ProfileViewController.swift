//
//  ProfileViewController.swift
//  neighbourhood
//
//  Created by Dioksa on 24.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

final class ProfileViewController: BaseViewController {
    @IBOutlet private weak var userLogoImageView: UIImageView!
    @IBOutlet private weak var userNameLabel: UILabel!
    @IBOutlet private weak var userMiniLogoImageView: UIImageView!
    @IBOutlet private weak var logoutButton: UIButton!
    @IBOutlet private weak var profileSettingsButton: DarkButton!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var initialsLabel: UILabel!
    @IBOutlet private weak var initialsSmallLabel: UILabel!
    
    @IBOutlet private weak var profileInfoButton: UIButton!
    @IBOutlet private weak var myInterestsButton: UIButton!
    @IBOutlet private weak var moreInfoButton: UIButton!
    
    @IBOutlet private weak var profileInfoBottomView: UIView!
    @IBOutlet private weak var myInterestsBottomView: UIView!
    @IBOutlet private weak var moreInfoBottomView: UIView!
    
    @IBOutlet private weak var spinner: UIActivityIndicatorView!
    
    // TODO: - Delete after test
    
    @IBOutlet private weak var profileIdTextField: UITextField!
    
    private let moreInfoView = MoreInfoView()
    private let profileView = ProfileInfoView()
    private let interestsView = MyInterestsView()
    private var scrollViewSetUp = false
    private var currentProfile: UserProfile?
    
    private lazy var views = [profileView, interestsView, moreInfoView]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTexts()
        moreInfoView.delegate = self
        interestsView.screenDelegate = self
        fetchUserProfile()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchUserProfile()
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
    
    private func createScrollPages() {
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        
        let numberOfPages = 3
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
        setDefaultColors(bottomView: myInterestsBottomView, button: myInterestsButton)
        setDefaultColors(bottomView: moreInfoBottomView, button: moreInfoButton)
        setDefaultColors(bottomView: profileInfoBottomView, button: profileInfoButton)
        
        switch page {
        case 0:
            setActiveColors(bottomView: profileInfoBottomView, button: profileInfoButton)
        case 1:
            setActiveColors(bottomView: myInterestsBottomView, button: myInterestsButton)
        case 2:
            setActiveColors(bottomView: moreInfoBottomView, button: moreInfoButton)
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
        BasicProfileRouter(in: navigationController).openPublicProfileViewController(profileId: Int(profileIdTextField.text ?? "") ?? 1)
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
    
    @IBAction private func moreInfoButtonDidTap(_ sender: UIButton) {
        setSelectedButton(for: 2)
        scrollToPage(2)
    }
    
    @IBAction func profileSettingsButtonDidTap(_ sender: UIButton) {
        BasicProfileRouter(in: navigationController).openProfileSettingsViewController()
    }
}

// MARK: - Configurations
private extension ProfileViewController {
    func configureImageViews() {
        userMiniLogoImageView.cornerRadius = userMiniLogoImageView.frame.height / 2
        userMiniLogoImageView.clipsToBounds = true
        userLogoImageView.cornerRadius = userLogoImageView.frame.height / 2
        userLogoImageView.clipsToBounds = true
    }
    
    func configureTexts() {
        profileSettingsButton.setTitle(R.string.localizable.profileSettingsButtonTitle(), for: .normal)
        profileInfoButton.setTitle(R.string.localizable.profileInfoTitle(), for: .normal)
        myInterestsButton.setTitle(R.string.localizable.myInterestsTitle(), for: .normal)
        moreInfoButton.setTitle(R.string.localizable.moreWordTitle(), for: .normal)
    }
}

// MARK: - REST requests
private extension ProfileViewController {
    func fetchUserProfile() {
        spinner.startAnimating()
        RestProfile(requestIdentifier: name).getUser { [weak self] (result) in
            switch result {
            case .success(let model):
                UserDefaults.standard.set(model.0?.profile.id, forKey: "currentId")
                self?.currentProfile = model.0?.profile
                self?.userNameLabel.text = model.0?.profile.fullName
                
                self?.profileView.updateProfileView(address: model.0?.profile.address,
                                                    email: model.0?.email,
                                                    birthday: model.0?.profile.birthday,
                                                    gender: model.0?.profile.gender)
                
                self?.interestsView.updateViewWithUserInterests(categories: model.0?.profile.interests)
                self?.defineElementsVisibility(avatar: model.0?.profile.avatar)
                
            case .failure(let error):
                Toast.show(message: Alert.ErrorMessage.serverUnavailable)
                switch error {
                case .unauthorized:
                    self?.spinner.stopAnimating()
                    RootRouter.shared.exitApp()
                default:
                    self?.spinner.stopAnimating()
                    break
                }
            }
        }
    }
    
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
        RestAuthorization(requestIdentifier: name).signOut {(_) in
            RootRouter.shared.exitApp()
        }
    }
    
    func defineElementsVisibility(avatar: UserAvatar?) {
        if let imageURL = avatar?.origin {
            userMiniLogoImageView.load(from: imageURL) { }
            userLogoImageView.load(from: imageURL) {
                self.spinner.stopAnimating()
            }
        } else {
            userMiniLogoImageView.image = R.image.logo_background_small()
            userLogoImageView.image = R.image.logo_background()
            spinner.stopAnimating()
        }
        
        initialsLabel.isHidden = avatar != nil
        initialsSmallLabel.isHidden = avatar != nil
        
        initialsSmallLabel.getNameInitials(fullName: userNameLabel.text)
        initialsLabel.getNameInitials(fullName: userNameLabel.text)
    }
}

// MARK: - UIScrollViewDelegate
extension ProfileViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        setSelectedButton(for: page)
    }
}

// MARK: - StaticTextDelegate
extension ProfileViewController: StaticTextDelegate {
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

// MARK: - MyInterestsViewDelegate
extension ProfileViewController: MyInterestsViewDelegate {
    func openMyInterestsScreen() {
        BasicProfileRouter(in: navigationController).openMyInterestsViewController(profile: currentProfile)
    }
}

// MARK: - AccountSwitcherDelegate
extension ProfileViewController: AccountSwitcherDelegate {
    func switchToProfile(addProfile: Bool, business: BusinessProfile?) {
        if addProfile {
            BusinessProfileRouter(in: self.navigationController).openAddBusinessProfileViewController(screenType: .add, delegate: self)
        } else if business != nil {
            (tabBarController as? MainScreenViewController)?.switchTo(type: .business, business: business)
        } else {
            (tabBarController as? MainScreenViewController)?.switchTo(type: .basic, business: nil)
        }
    }
}

// MARK: - TabBarUpdatableDelegate
extension ProfileViewController: TabBarUpdatableDelegate {
    func updateBottomBar(with profile: BusinessProfile?) {
        (tabBarController as? MainScreenViewController)?.switchTo(type: .business, business: profile)
    }
}
