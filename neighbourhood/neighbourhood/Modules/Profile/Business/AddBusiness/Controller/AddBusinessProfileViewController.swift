//
//  AddBusinessProfileViewController.swift
//  neighbourhood
//
//  Created by Dioksa on 13.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import TagListView
import GBKSoftTextField

enum TypeOfScreenAction {
    case create, edit
}

protocol TabBarUpdatableDelegate: AnyObject {
    func updateBottomBar(with profile: BusinessProfile?)
}

protocol BusinessProfileUpdatableDelegate: AnyObject {
    func updateProfile(with profile: BusinessProfile?)
    func updateBottomBar(with profile: BusinessProfile?)
}

private let staticRowHeight: CGFloat = 28.0
private let maxRowCount: CGFloat = 5.0

final class AddBusinessProfileViewController: BaseViewController {
    @IBOutlet private weak var screenTitleLabel: UILabel!
    @IBOutlet private weak var businessAvatarImageView: UIImageView!
    @IBOutlet private weak var emptyAvatarView: UIView!
    @IBOutlet private weak var addImageSmallButton: UIButton!
    @IBOutlet private weak var addImageBigButton: UIButton!
    @IBOutlet private weak var bottomShadowView: UIView!
    
    @IBOutlet private weak var nameTextField: CustomTextField!
    @IBOutlet private weak var descriptionTextField: CustomTextField!
    @IBOutlet private weak var addressTextField: CustomTextField!
    @IBOutlet private weak var categoriesTextField: CustomTextField!
    @IBOutlet private weak var websiteTextField: CustomTextField!
    @IBOutlet private weak var emailTextField: CustomTextField!
    @IBOutlet private weak var phoneTextField: CustomTextField!
    
    @IBOutlet private weak var tagView: TagListView!
    @IBOutlet private weak var createButton: DarkButton!
    @IBOutlet private weak var spinner: UIActivityIndicatorView!
    @IBOutlet private weak var addAvatarTitleLabel: UILabel!
    
    @IBOutlet private var locationButtons: [UIButton]!
    
    @IBOutlet private weak var onlyMeButton: UIButton!
    @IBOutlet private weak var tenMilesButton: UIButton!
    @IBOutlet private weak var increaseMiles: UIButton!
    
    @IBOutlet private weak var onlyMeHintLabel: UILabel!
    @IBOutlet private weak var tenMilesHintLabel: UILabel!
    @IBOutlet private weak var increaseHintLabel: UILabel!
    
    @IBOutlet weak var purchasedRadiusView: UIStackView!
    @IBOutlet weak var purchasedTitleButton: UIButton!
    @IBOutlet weak var purchasedCostLabel: UILabel!
    @IBOutlet weak var purchasedHintLabel: UILabel!

    private var selectedCategories = [HashtagModel]()
    private var categories: [CategoriesData]?
    
    private var latitude: Float?
    private var longitude: Float?
    private var placeId: String?
    private var selectedImage: UIImage?
    
    private let validation = ValidationManager()
    private let addressFormatter = AddressFormatter()
    private lazy var businessProfileManager: RestBusinessProfileManager = RestService.shared.createOperationsManager(from: self, type: RestBusinessProfileManager.self)
    private lazy var categoriesManager: RestCategoriesManager = RestService.shared.createOperationsManager(from: self, type: RestCategoriesManager.self)
    private lazy var mediaProcessor: MediaProcessor = MediaProcessor(viewController: self, delegate: self)

    var screenType: TypeOfScreenAction = .create
    var businessProfile: BusinessProfile?
    var selectedAddress: AddressModel?

    private var openPlanSelection = false
    
    weak var delegate: TabBarUpdatableDelegate?
    weak var profileDelegate: BusinessProfileUpdatableDelegate?
    
    private let arrayOfMiles: [LocationRadiusVisibility] = [.onlyMe, .defaultRadius, .moreMiles(-1) ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        spinner.stopAnimating()
        fillDataWithProfileInfo()
        setTexts()
        configureTagView()
        configureImageViews()
        configureElementsVisibility()
        bottomShadowView.dropShadow(color: R.color.greyStroke()!, opacity: 0.3, offSet: CGSize(width: 0, height: -5), radius: 3.0)
    }
    
    override var isBottomPaddingNeeded: Bool {
        return false
    }
    
    private func defineSelectedButton() -> LocationRadiusVisibility? {
        if purchasedTitleButton.currentImage == R.image.radio_button_active() {
            return purchasedTitleButton.tag == 0 ? nil : .moreMiles(purchasedTitleButton.tag)
        }
        for (index, button) in locationButtons.enumerated() {
            if button.currentImage == R.image.radio_button_active() {
                return arrayOfMiles[index]
            }
        }
        
        return nil
    }
    
    private func defineMilesButton(_ miles: LocationRadiusVisibility?) {
        switch miles {
        case .onlyMe:
            onlyMeButton.setImage(R.image.radio_button_active(), for: .normal)
            [tenMilesButton, increaseMiles].forEach { $0?.setImage(R.image.radio_button_inactive(), for: .normal) }
        case .defaultRadius:
            tenMilesButton.setImage(R.image.radio_button_active(), for: .normal)
            [onlyMeButton, increaseMiles].forEach { $0?.setImage(R.image.radio_button_inactive(), for: .normal) }
        default:
            increaseMiles.setImage(R.image.radio_button_active(), for: .normal)
            [onlyMeButton, tenMilesButton].forEach { $0?.setImage(R.image.radio_button_inactive(), for: .normal) }
        }

        if SubscriptionsManager.shared.currentSubscription != nil {
            SubscriptionsManager.shared.delegate = self
            SubscriptionsManager.shared.getAvailableSubscriptions()
        }
    }
    
    func removeAvatar() {
        addImageSmallButton.isHidden = true
        emptyAvatarView.isHidden = false
        selectedImage = nil
    }
    
    // MARK: - Private actions
    @IBAction func backButtonDidTap(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func locationButtonDidTap(_ sender: UIButton) {
        locationButtons.forEach { $0.setImage(R.image.radio_button_inactive(), for: .normal)}
        sender.setImage(R.image.radio_button_active(), for: .normal)
    }
    
    @IBAction func addPhotoButtonDidTap(_ sender: UIButton) {
        var options: [MediaProcessingOption] = [.capture(), .gallery()]
        if businessProfile?.avatar != nil {
            options.append(.remove())
        }
        mediaProcessor.openMediaOptions(options)
    }
    
    @IBAction func createButtonDidTap(_ sender: UIButton) {
        guard formIsValid() else {
            return
        }
        
        guard let name = nameTextField.text,
            let description = descriptionTextField.text,
            let address = addressTextField.text,
            let placeId = self.placeId,
            let latitude = latitude,
            let longitude = longitude else {
                NSLog("🔥 Check fields at AddBusinessProfileViewController")
                return
        }
        
        let categoriesIds = selectedCategories.map { $0.id }.map { String($0) }
        
        let phoneString = String((phoneTextField.text ?? "").unicodeScalars.filter(CharacterSet.decimalDigits.contains))
        var radius: LocationRadiusVisibility? = defineSelectedButton()
        switch radius {
        case .moreMiles(let miles):
            if miles == -1 {
                radius = .defaultRadius
                openPlanSelection = true
            }
        default:
            break
        }
        
        let data = BusinessProfileData(id: businessProfile?.id,
                                        fullName: name,
                                        description: description,
                                        address: address,
                                        publicAddress: address,
                                        placeId: placeId,
                                        longitude: longitude,
                                        latitude: latitude,
                                        radius: radius,
                                        hashtagIds: categoriesIds.joined(separator: ","),
                                        site: websiteTextField.text,
                                        email: emailTextField.text,
                                        phone: phoneString)
        
        if screenType == .create {
            registerBusinessProfile(data: data, image: selectedImage)
        } else {
            updateBusinessProfile(data: data, image: selectedImage)
        }
    }
}

// MARK: - UI Configurations
private extension AddBusinessProfileViewController {
    func setTexts() {
        addAvatarTitleLabel.text = R.string.localizable.addAvatarTitle()
        
        nameTextField.title = R.string.localizable.businessNameTitle()
        nameTextField.placeholder = R.string.localizable.businessNamePlaceholder()
        
        descriptionTextField.title = R.string.localizable.businessDescriptionTitle()
        descriptionTextField.placeholder = R.string.localizable.businessDescriptionPlaceholder()
        
        addressTextField.title = R.string.localizable.businessAddressTitle()
        addressTextField.placeholder = R.string.localizable.businessAddressPlaceholder()
        
        categoriesTextField.title = R.string.localizable.businessCategoryTitle()
        categoriesTextField.placeholder = R.string.localizable.businessCategoryPlaceholder()
        
        websiteTextField.title = R.string.localizable.businessWebsiteTitle()
        websiteTextField.placeholder = R.string.localizable.businessWebsitePlaceholder()
        
        emailTextField.title = R.string.localizable.businessEmailTitle()
        emailTextField.placeholder = R.string.localizable.businessEmailPlaceholder()
        
        phoneTextField.title = R.string.localizable.businessPhoneTitle()
        phoneTextField.placeholder = R.string.localizable.businessPhonePlaceholder()
        
        onlyMeHintLabel.text = R.string.localizable.onlyMeHint()
        tenMilesHintLabel.text = R.string.localizable.tensMilesHint()
        increaseHintLabel.text = R.string.localizable.increaseMilesHint()
    }

    func configureTagView() {
        tagView.textFont = R.font.poppinsMedium(size: 13)!
        
        if screenType == .create {
            tagView.isHidden = selectedCategories.isEmpty
        } else {
            tagView.isHidden = businessProfile?.hashtags.isEmpty ?? true
        }
        
        tagView.delegate = self
    }
    
    func configureImageViews() {
        businessAvatarImageView.layer.cornerRadius = businessAvatarImageView.frame.height / 2
        businessAvatarImageView.clipsToBounds = true
    }
    
    func configureElementsVisibility() {
        addImageSmallButton.isHidden = screenType == .create
        emptyAvatarView.isHidden = screenType == .edit
        
        websiteTextField.isHidden = screenType == .create
        emailTextField.isHidden = screenType == .create
        phoneTextField.isHidden = screenType == .create
    }
    
    func fillDataWithProfileInfo() {
        if screenType == .edit {
            screenTitleLabel.text = R.string.localizable.editBusinessProfileScreenTitle()
            createButton.setTitle(R.string.localizable.saveButtonTitle(), for: .normal)
            
            if let imageUrl = businessProfile?.avatar?.formatted?.medium {
                spinner.startAnimating()
                businessAvatarImageView.load(from: imageUrl) { [weak self] in
                    guard let strongSelf = self else { return }
                    
                    strongSelf.selectedImage = strongSelf.businessAvatarImageView.image
                    strongSelf.spinner.stopAnimating()
                }
            } else {
                spinner.stopAnimating()
            }
            
            businessProfile?.hashtags.forEach {
                tagView.addTag($0.name)
            }
            
            selectedCategories = businessProfile?.hashtags ?? []
            nameTextField.text = businessProfile?.fullName
            descriptionTextField.text = businessProfile?.description
            addressTextField.text = businessProfile?.address
            websiteTextField.text = businessProfile?.site
            emailTextField.text = businessProfile?.email

            phoneTextField.text = businessProfile?.phone?.formattedPhoneNumber
            
            defineMilesButton(businessProfile?.radius)
            
            latitude = businessProfile?.latitude
            longitude = businessProfile?.longitude
            placeId = businessProfile?.placeId
            
            increaseMiles.setTitle(R.string.localizable.changeRadiusTitle(), for: .normal)
        } else {
            spinner.stopAnimating()
            screenTitleLabel.text = R.string.localizable.addBusinessProfileTitle()
            createButton.setTitle(R.string.localizable.createBusinessProfileButtonTitle(), for: .normal)
            increaseMiles.setTitle(R.string.localizable.increaseRadiusTitle(), for: .normal)
            defineMilesButton(.defaultRadius)
        }
    }
}

// MARK: - REST requests and validation
private extension AddBusinessProfileViewController {
    func formIsValid() -> Bool {
        var valid = true
        
        [nameTextField, descriptionTextField, addressTextField, categoriesTextField, phoneTextField].forEach { $0?.error = nil }
        
        if let validationError = validation.validateFullName(value: nameTextField.text)
            .errorMessage(field: R.string.localizable.businessNameTitle()) {
            nameTextField.error = validationError.capitalizingFirstLetter()
            valid = false
        }
        
        if let validationError = validation.validateDescription(value: descriptionTextField.text)
            .errorMessage(field: R.string.localizable.businessDescriptionTitle()) {
            descriptionTextField.error = validationError.capitalizingFirstLetter()
            valid = false
        }

        if let validationError = validation
            .validateRequired(value: addressTextField.text)
            .errorMessage(field: R.string.localizable.businessAddressTitle()) {
            addressTextField.error = validationError.capitalizingFirstLetter()
            valid = false
        } else if addressTextField?.text != businessProfile?.address {
            if let validationError = validation
                .validateAddress(value: selectedAddress?.city)
                .errorMessage(field: R.string.localizable.businessAddressTitle()) {
                addressTextField.error = validationError.capitalizingFirstLetter()
                valid = false
            }
        }
        
        if let validationError = validation.validateInterests(value: selectedCategories)
            .errorMessage(field: R.string.localizable.businessCategory()) {
            categoriesTextField.error = validationError.capitalizingFirstLetter()
            valid = false
        }
        
        if let phoneText = phoneTextField.text, phoneText != "", phoneText.count < 13 {
            if let validationError = validation.validatePhone(value: phoneTextField.title)
                .errorMessage(field: R.string.localizable.businessPhoneTitle()) {
                phoneTextField.error = validationError.capitalizingFirstLetter()
                valid = false
            }
        }
        
        if valid && selectedImage == nil {
            Toast.show(message: R.string.localizable.blankImageErrorMessage())
            valid = false
        }
        
        if valid && !validation.checkInternetConnection() {
            Toast.show(message: R.string.localizable.internetConnectionError())
        }
        
        return valid
    }
    
    func registerBusinessProfile(data: BusinessProfileData, image: UIImage?) {
        guard ValidationManager().checkInternetConnection() else {
            Toast.show(message: R.string.localizable.internetConnectionError())
            return
        }
        
        businessProfileManager.addProfile(data: data, image: image)
            .onStateChanged { [weak self] (state) in
                switch state {
                case .started:
                    self?.createButton.isLoading = true
                case .ended:
                    self?.createButton.isLoading = false
                }
        }
        .onComplete { [weak self] (result) in
            AnalyticsService.logBussinessProfileCreated()
            guard let self = self else {
                return
            }
            if let profile = result.result {
                ArchiveService.shared.currentProfile = profile.selectorProfile
                if self.screenType == .create {
                    ChatUnreadMessageService.shared.update(profileId: profile.id, hasUnreadMessages: false)
                }
            }
            
            if self.delegate != nil {
                self.delegate?.updateBottomBar(with: result.result)
            } else {
                self.profileDelegate?.updateBottomBar(with: result.result)
            }
            
            MainScreenRouter(in: self.navigationController).openMyProfile()
            if self.openPlanSelection {
                BusinessProfileRouter(in: self.navigationController).openPaymentPlansViewController()
            }

            Toast.show(message: R.string.localizable.createdBusinessProfile())
        } .onError { [weak self] (error) in
            self?.handleError(error)
        } .run()
    }
    
    func updateBusinessProfile(data: BusinessProfileData, image: UIImage?) {
        guard ValidationManager().checkInternetConnection() else {
            Toast.show(message: R.string.localizable.internetConnectionError())
            return
        }
        
        businessProfileManager.updateProfile(id: data.id!, data: data, image: image)
            .onStateChanged { [weak self] (state) in
                switch state {
                case .started:
                    self?.createButton.isLoading = true
                case .ended:
                    self?.createButton.isLoading = false
                }
        }
        .onComplete { [weak self] (result) in
            guard let self = self else {
                return
            }
            
            self.navigationController?.popViewController(animated: true)
            if self.openPlanSelection {
                BusinessProfileRouter(in: self.navigationController).openPaymentPlansViewController()
            }
            guard let newProfile = result.result else {
                return
            }
            var user = ArchiveService.shared.userModel
            let businessProfiles = user?.businessProfiles?.map({ (profile) -> BusinessProfile in
                if profile.id == newProfile.id {
                    return newProfile
                }
                return profile
            })
            user?.businessProfiles = businessProfiles
            ArchiveService.shared.userModel = user
            if ArchiveService.shared.currentProfile?.id == newProfile.id {
                ArchiveService.shared.currentProfile = newProfile.selectorProfile
            }
            Toast.show(message: R.string.localizable.updatedBusinessProfile())
        } .onError { [weak self] (error) in
            self?.handleError(error)
        } .run()
    }
}

// MARK: - GMSAutocompleteResultsViewControllerDelegate
extension AddBusinessProfileViewController: GMSAutocompleteResultsViewControllerDelegate {
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController, didFailAutocompleteWithError error: Error) {
        // TODO: - Handle error
    }

    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didAutocompleteWith place: GMSPlace) {
        resultsController.dismiss(animated: true, completion: nil)

        latitude = Float(place.coordinate.latitude)
        longitude = Float(place.coordinate.longitude)
        placeId = place.placeID

        addressTextField.error = nil
        let address = addressFormatter.getAddressFromPlace(place)
        addressTextField.text = address?.addressString
        if let validationError = validation.validateAddress(value: address?.city)
            .errorMessage(field: R.string.localizable.addressTitle()) {
            addressTextField.error = validationError.capitalizingFirstLetter()
            return
        }
        selectedAddress = address
    }
}

// MARK: - UISearchBarDelegate
extension AddBusinessProfileViewController: UISearchBarDelegate {
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }
}

// MARK: - TagListViewDelegate
extension AddBusinessProfileViewController: TagListViewDelegate {
    func tagRemoveButtonPressed(_ title: String, tagView: TagView, sender: TagListView) -> Void {
        if let index = selectedCategories.firstIndex(where: { $0.name == title }) {
            selectedCategories.remove(at: index)
            self.tagView.isHidden = selectedCategories.isEmpty
        }
        
        if selectedCategories.isEmpty {
            if let validationError = validation
                .validateInterests(value: selectedCategories)
                .errorMessage(field: R.string.localizable.myInterestsTitle()) {
                categoriesTextField.error = validationError
            }
        } else if selectedCategories.count <= 2 {
            categoriesTextField.error = nil
        }
        
        self.tagView.removeTag(title)
        self.tagView.layoutSubviews()
    }
}

// MARK: - UITextFieldDelegate
extension AddBusinessProfileViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case nameTextField:
            descriptionTextField.becomeFirstResponder()
        case descriptionTextField:
            categoriesTextField.becomeFirstResponder()
        case categoriesTextField:
            websiteTextField.becomeFirstResponder()
        case websiteTextField:
            emailTextField.becomeFirstResponder()
        case emailTextField:
            phoneTextField.becomeFirstResponder()
        default:
            view.endEditing(true)
        }
        
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == phoneTextField {
            guard let text = textField.text else { return false }
            let newString = (text as NSString).replacingCharacters(in: range, with: string)
            textField.text = newString.formattedPhoneNumber
            return false
        } else {
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
        } else if textField == categoriesTextField {
            navigationController?.isNavigationBarHidden = true
            present(MyPostsRouter().createCategoriesController(delegate: self), animated: true, completion: nil)
            return false
        } else {
            return true
        }
    }
}

// MARK: - ChoseCategoryDelegate
extension AddBusinessProfileViewController: ChoseCategoryDelegate {
    func getCategory(by data: HashtagModel) {
        if !selectedCategories.contains(data) {
            tagView.isHidden = false
            if selectedCategories.count >= 5 {
                categoriesTextField.error = R.string.localizable.categoriesLimitErrorMessage()
            } else {
                categoriesTextField.error = nil
                tagView.addTag(data.name)
                selectedCategories.append(data)

                categoriesTextField.text = nil
            }
        } else {
            Toast.show(message: R.string.localizable.categoryWasAddedError())
        }
    }
}


extension AddBusinessProfileViewController: SubscriptionsManagerDelegate {
    func availableSubscriptionsUpdated(_ subscriptions: [IAPProductModel]) {
        guard let purchasedPlan = SubscriptionsManager.shared.currentSubscription,
            let planData = subscriptions.first(where: { $0.id == purchasedPlan.productName }) else {
            return
        }
        purchasedRadiusView.isHidden = false
        purchasedTitleButton.setTitle(planData.name, for: .normal)
        purchasedCostLabel.text =  R.string.localizable.planPricePerMonthCost(planData.priceString ?? "")
        purchasedHintLabel.text = R.string.localizable.planRadiusAndPrice(planData.name, planData.priceString ?? "")
        switch planData.id {
        case "r100":
            purchasedTitleButton.tag = 100
        case "r500":
            purchasedTitleButton.tag = 500
        case "worldwide":
            purchasedTitleButton.tag = 12430
        default:
            break
        }
        switch businessProfile?.radius {
        case .moreMiles(_):
            purchasedTitleButton.setImage(R.image.radio_button_active(), for: .normal)
            [onlyMeButton, tenMilesButton, increaseMiles].forEach { $0?.setImage(R.image.radio_button_inactive(), for: .normal) }
        default:
            break
        }

    }

    func currentSubscriptionReceived(_ currentSubscription: PaymentPlanModel?) {
    }

    func subscriptionProcessBegan(_ process: SubscriptionProcess) {
        if process == .fetchAvailableSubscriptions {

        }
    }

    func subscriptionProcessEnd(_ process: SubscriptionProcess?) {
    }

    func subscriptionProcessFailed(_ process: SubscriptionProcess?, with error: Error) {
    }

    func subscriptionProcessEndWithCancel(_ process: SubscriptionProcess?) {
    }
}

// MARK: - MediaProcessing

extension AddBusinessProfileViewController: MediaProcessorDelegate {
    func mediaOptionProcessed(result: MediaProcessingResult) {
        switch result {
        case .image(let image, _):
            emptyAvatarView.isHidden = true
            addImageSmallButton.isHidden = false
            selectedImage = image
            businessAvatarImageView.image = image
        case .remove:
            removeAvatar()
        default:
            break
        }
    }
}
