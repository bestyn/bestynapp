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

enum TypeOfBusinessScreen {
    case add, edit
}

protocol TabBarUpdatableDelegate: AnyObject {
    func updateBottomBar(with profile: BusinessProfile?)
}

protocol BusinessProfileUpdatableDelegate: AnyObject {
    func updateProfile(with profile: BusinessProfile?)
}

private let staticRowHeight: CGFloat = 28.0
private let maxRowCount: CGFloat = 5.0

final class AddBusinessProfileViewController: BaseViewController, AvatarChanging {
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
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var tagView: TagListView!
    @IBOutlet private weak var additionalSpaceView: UIView!
    @IBOutlet private weak var createButton: DarkButton!
    @IBOutlet private weak var spinner: UIActivityIndicatorView!
    @IBOutlet private weak var addAvatarTitleLabel: UILabel!
    
    @IBOutlet private var locationButtons: [UIButton]!
    
    @IBOutlet private weak var onlyMeButton: UIButton!
    @IBOutlet private weak var tenMilesButton: UIButton!
    @IBOutlet private weak var increaseMiles: UIButton!
    
    private var selectedCategories = [CategoriesData]()
    private var categories: [CategoriesData]?
    
    private var latitude: Float?
    private var longitude: Float?
    private var selectedImage: UIImage?
    
    private let validation = ValidationManager()
    private let addressFormatter = AddressFormatter()
    
    var imagePicker = UIImagePickerController()
    var screenType: TypeOfBusinessScreen = .add
    var businessProfile: BusinessProfile?
    
    weak var delegate: TabBarUpdatableDelegate?
    weak var profileDelegate: BusinessProfileUpdatableDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        spinner.stopAnimating()
        fillDataWithProfileInfo()
        setTexts()
        configureTableView()
        hideViewWhenTappedAround()
        configureTagView()
        configureImageViews()
        imagePicker.delegate = self
        configureElementsVisibility()
        bottomShadowView.dropShadow(color: R.color.greyStroke()!, opacity: 0.3, offSet: CGSize(width: 0, height: -5), radius: 3.0)
    }
    
    override var isNavigationBarVisible: Bool {
        return false
    }
    
    private func hideViewWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideTableView))
        tap.delegate = self
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc private func hideTableView() {
        tableView.isHidden = true
        additionalSpaceView.isHidden = true
        view.endEditing(true)
    }
    
    private func defineSelectedButton() -> LocationRadiusVisibility {
        for (index, button) in locationButtons.enumerated() {
            if button.currentImage == R.image.radio_button_active() {
                return LocationRadiusVisibility.allCases[index]
            }
        }
        
        return .tenMiles
    }
    
    private func defineMilesButton(_ miles: LocationRadiusVisibility?) {
        switch miles {
        case .onlyMe:
            onlyMeButton.setImage(R.image.radio_button_active(), for: .normal)
            [tenMilesButton, increaseMiles].forEach { $0?.setImage(R.image.radio_button_inactive(), for: .normal) }
        case .tenMiles:
            tenMilesButton.setImage(R.image.radio_button_active(), for: .normal)
            [onlyMeButton, increaseMiles].forEach { $0?.setImage(R.image.radio_button_inactive(), for: .normal) }
        default:
            increaseMiles.setImage(R.image.radio_button_active(), for: .normal)
            [onlyMeButton, tenMilesButton].forEach { $0?.setImage(R.image.radio_button_inactive(), for: .normal) }
        }
    }
    
    func removeAvatar() {
        addImageSmallButton.isHidden = true
        emptyAvatarView.isHidden = false
        addImageBigButton.isHidden = false
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
        changeAvatar()
    }
    
    @IBAction func createButtonDidTap(_ sender: UIButton) {
        guard formIsValid() else {
            return
        }
        
        guard let name = nameTextField.text,
            let description = descriptionTextField.text,
            let address = addressTextField.text,
            let latitude = latitude,
            let longitude = longitude else {
                assertionFailure("🔥 Check fields at AddBusinessProfileViewController")
                return
        }
        
        let categoriesIds = selectedCategories.map { $0.id }.map { String($0) }
        
        createButton.isLoading = true
        let phoneString = String((phoneTextField.text ?? "").unicodeScalars.filter(CharacterSet.decimalDigits.contains))
        
        let data = BusinessProfileModel(id: businessProfile?.id,
                                        fullName: name,
                                        description: description,
                                        address: address,
                                        longitude: longitude,
                                        latitude: latitude,
                                        radius: defineSelectedButton(),
                                        categoryIds: categoriesIds.joined(separator: ","),
                                        site: websiteTextField.text,
                                        email: emailTextField.text,
                                        phone: Int(phoneString))
        
        if screenType == .add {
            registerBusinessProfile(data: data, image: selectedImage) { [weak self] in
                self?.createButton.isLoading = false
            }
        } else {
            updateBusinessProfile(data: data, image: selectedImage) { [weak self] in
                self?.createButton.isLoading = false
            }
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
    }
    
    func configureTableView() {
        tableView.register(R.nib.dropDownInterestsCell)
        tableView.isHidden = true
        additionalSpaceView.isHidden = tableView.isHidden
        tableView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
    }
    
    func defineTableViewHeight() {
        let maxHeight: CGFloat = staticRowHeight * maxRowCount
        let fullTableViewHeight = staticRowHeight * CGFloat(categories?.count ?? 0)
        
        if fullTableViewHeight < maxHeight {
            tableViewHeightConstraint.constant = fullTableViewHeight
        } else {
            tableViewHeightConstraint.constant = maxHeight
        }
    }
    
    func configureTagView() {
        tagView.textFont = R.font.poppinsMedium(size: 13)!
        
        if screenType == .add {
            tagView.isHidden = selectedCategories.isEmpty
        } else {
            tagView.isHidden = businessProfile?.categories.isEmpty ?? true
        }
        
        tagView.delegate = self
    }
    
    func animate(toogle: Bool) {
        if toogle {
            UIView.animate(withDuration: 0.3) { [weak self] in
                self?.tableView.isHidden = false
                self?.additionalSpaceView.isHidden = false
            }
        } else {
            UIView.animate(withDuration: 0.1) { [weak self] in
                self?.tableView.isHidden = true
                self?.additionalSpaceView.isHidden = true
            }
        }
    }
    
    func configureImageViews() {
        businessAvatarImageView.layer.cornerRadius = businessAvatarImageView.frame.height / 2
        businessAvatarImageView.clipsToBounds = true
    }
    
    func configureElementsVisibility() {
        addImageSmallButton.isHidden = screenType == .add
        emptyAvatarView.isHidden = screenType == .edit
        addImageBigButton.isHidden = screenType == .edit
        
        websiteTextField.isHidden = screenType == .add
        emailTextField.isHidden = screenType == .add
        phoneTextField.isHidden = screenType == .add
    }
    
    func fillDataWithProfileInfo() {
        if screenType == .edit {
            screenTitleLabel.text = R.string.localizable.editBusinessProfileScreenTitle()
            createButton.setTitle(R.string.localizable.saveButtonTitle(), for: .normal)
 
            if let imageUrl = businessProfile?.avatar?.origin {
                spinner.startAnimating()
                businessAvatarImageView.load(from: imageUrl) { [weak self] in
                    self?.selectedImage = self?.businessAvatarImageView.image
                    self?.spinner.stopAnimating()
                }
            } else {
                spinner.stopAnimating()
            }
            
            businessProfile?.categories.forEach {
                tagView.addTag($0.title)
            }
            
            selectedCategories = businessProfile?.categories ?? []
            nameTextField.text = businessProfile?.fullName
            descriptionTextField.text = businessProfile?.description
            addressTextField.text = businessProfile?.address
            websiteTextField.text = businessProfile?.site
            emailTextField.text = businessProfile?.email
            
            if let phone = businessProfile?.phone {
                phoneTextField.formattedNumber(number: String(phone))
            } else {
                phoneTextField.text = ""
            }
            
            defineMilesButton(businessProfile?.radius)
            
            latitude = businessProfile?.latitude
            longitude = businessProfile?.longitude
            
            increaseMiles.setTitle(R.string.localizable.changeRadiusTitle(), for: .normal)
        } else {
            spinner.stopAnimating()
            screenTitleLabel.text = R.string.localizable.addBusinessProfileTitle()
            createButton.setTitle(R.string.localizable.createBusinessProfileButtonTitle(), for: .normal)
            increaseMiles.setTitle(R.string.localizable.increaseRadiusTitle(), for: .normal)
            defineMilesButton(.tenMiles)
        }
    }
}

// MARK: - REST requests and validation
private extension AddBusinessProfileViewController {
    func formIsValid() -> Bool {
        var valid = true
        
        [nameTextField, descriptionTextField, addressTextField, categoriesTextField].forEach { $0?.error = nil }
        
        if let validationError = validation
            .validateFullName(value: nameTextField.text)
            .errorMessage(field: R.string.localizable.businessNameTitle()) {
            nameTextField.error = validationError.capitalizingFirstLetter()
            valid = false
        }
        
        if let validationError = validation
            .validateDescription(value: descriptionTextField.text)
            .errorMessage(field: R.string.localizable.businessDescriptionTitle()) {
            descriptionTextField.error = validationError.capitalizingFirstLetter()
            valid = false
        }
        
        if addressTextField?.text == businessProfile?.address {
            addressFormatter.houseNumber = ""
        }
        
        if addressTextField.text == nil || addressTextField.text == "" {
            if let validationError = validation
                .validateRequired(value: addressTextField.text)
                .errorMessage(field: R.string.localizable.businessAddressTitle()) {
                addressTextField.error = validationError.capitalizingFirstLetter()
                valid = false
            }
        } else if addressFormatter.houseNumber == nil {
            if let validationError = validation
                .validateAddress(value: addressFormatter.houseNumber)
                .errorMessage(field: R.string.localizable.businessAddressTitle()) {
                addressTextField.error = validationError.capitalizingFirstLetter()
                valid = false
            }
        }
        
        if let validationError = validation
            .validateInterests(value: selectedCategories)
            .errorMessage(field: R.string.localizable.businessCategory()) {
            categoriesTextField.error = validationError.capitalizingFirstLetter()
            valid = false
        }

        if valid && selectedImage == nil {
            Toast.show(message: R.string.localizable.blankImageErrorMessage())
            valid = false
        }
        
        return valid
    }
    
    func registerBusinessProfile(data: BusinessProfileModel, image: UIImage?, completion: @escaping () -> Void) {
        RestBusinessProfile(requestIdentifier: name).addProfile(data: data, image: image) { [weak self] (result) in
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let model):
                UserDefaults.standard.set(model.0?.id, forKey: "currentId")
                self.navigationController?.popViewController(animated: true)
                self.delegate?.updateBottomBar(with: model.0)
                Toast.show(message: R.string.localizable.createdBusinessProfile())
            case .failure(let error):
                self.handleError(error)
            }
            
            completion()
        }
    }
    
    func updateBusinessProfile(data: BusinessProfileModel, image: UIImage?, completion: @escaping () -> Void) {
        RestBusinessProfile(requestIdentifier: name).updateProfile(data: data, image: image) { [weak self] (result) in
            guard let self = self else {
                return
            }
            
            switch result {
            case .success(let model):
                UserDefaults.standard.set(model.0?.id, forKey: "currentId")
                self.navigationController?.popViewController(animated: true)
                self.profileDelegate?.updateProfile(with: model.0)
                Toast.show(message: R.string.localizable.updatedBusinessProfile())
            case .failure(let error):
                self.handleError(error)
            }
            
            completion()
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension AddBusinessProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.dropDownInterestsCell, for: indexPath) else {
            assertionFailure("🔥 Error occurred while creating DropDownInterestsCell")
            return UITableViewCell() }
        
        if let categories = categories, !categories.isEmpty {
            cell.updateCell(title: categories[indexPath.row].title)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let  categories = categories, !categories.isEmpty else {
            assertionFailure("🔥 Array with categories is empty or nil")
            return
        }
        
        if !selectedCategories.contains(categories[indexPath.row]) {
            tagView.isHidden = false
            
            if selectedCategories.count >= 5 {
                categoriesTextField.error = R.string.localizable.categoriesLimitErrorMessage()
            } else {
                categoriesTextField.error = nil
                tagView.addTag(categories[indexPath.row].title)
                selectedCategories.append(categories[indexPath.row])
                
                categoriesTextField.text = nil
                hideTableView()
            }
        } else {
            Toast.show(message: R.string.localizable.categoryWasAddedError())
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 28.0
    }
}

// MARK: - GMSAutocompleteResultsViewControllerDelegate
extension AddBusinessProfileViewController: GMSAutocompleteResultsViewControllerDelegate {
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController, didFailAutocompleteWithError error: Error) {
        // TODO: - Handle error
    }
    
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didAutocompleteWith place: GMSPlace) {
        latitude = Float(place.coordinate.latitude)
        longitude = Float(place.coordinate.longitude)
        
        addressFormatter.getAddressFromLatLon(
            address: place.formattedAddress,
            textField: addressTextField) { [weak self] in
                
                guard self?.addressFormatter.houseNumber != nil else {
                    resultsController.dismiss(animated: true, completion: nil)
                    
                    let validationError = self?.validation
                        .validateAddress(value: self?.addressFormatter.houseNumber)
                        .errorMessage(field: R.string.localizable.addressTitle())
                    
                    self?.addressTextField.error = validationError?.capitalizingFirstLetter()
                    return
                }
                
                resultsController.dismiss(animated: true, completion: nil)
        }
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
        if let index = selectedCategories.firstIndex(where: { $0.title == title }) {
            selectedCategories.remove(at: index)
            self.tagView.isHidden = selectedCategories.isEmpty
        }
        
        if selectedCategories.isEmpty {
            hideTableView()
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

// MARK: - UIGestureRecognizerDelegate
extension AddBusinessProfileViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let touchView = touch.view, touchView.isDescendant(of: tableView) || touchView.isDescendant(of: tagView) {
            return false
        } else {
            hideTableView()
            return true
        }
    }
}

// MARK: - UITextFieldDelegate
extension AddBusinessProfileViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case nameTextField:
            descriptionTextField.becomeFirstResponder()
        case descriptionTextField:
            addressTextField.becomeFirstResponder()
        case addressTextField:
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
            textField.formattedNumber(number: newString)
            return false
        } else {
            return true
        }
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if textField == categoriesTextField {
            categoriesTextField.error = nil
            
            guard let text = textField.text, text.count > 0 else {
                self.animate(toogle: false)
                return
            }
            
            RestCategories(requestIdentifier: name).getCategories(title: text) { [weak self] (result) in
                guard let self = self else {
                    return
                }
                
                switch result {
                case .success(let model):
                    self.categories = model.0
                    self.defineTableViewHeight()
                    self.tableView.reloadData()
                    self.animate(toogle: true)
                case .failure(let error):
                    self.handleError(error)
                }
            }
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

// MARK: - UIImagePickerControllerDelegate
extension AddBusinessProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            return
        }
        
        emptyAvatarView.isHidden = true
        addImageBigButton.isHidden = true
        addImageSmallButton.isHidden = false
        selectedImage = image
        businessAvatarImageView.image = image
        imagePicker.dismiss(animated: true, completion: nil)
    }
}
