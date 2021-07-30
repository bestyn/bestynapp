//
//  ProfileInfoView.swift
//  neighbourhood
//
//  Created by Artem Korzh on 08.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import GooglePlaces
import GoogleMaps
import GBKSoftTextField

@objc protocol SettingsProfileInfoViewDelegate: class {
    func profileInfoViewPresenter() -> UIViewController
    func profileInfoViewChangeImage()
    func goToBasicProfile()
}

@IBDesignable
final class SettingsProfileInfoView: UIView, ErrorHandling {

    @IBOutlet private weak var avatarView: AvatarView!

    @IBOutlet private weak var fullNameTextField: CustomTextField!
    @IBOutlet private weak var addressTexField: CustomTextField!
    @IBOutlet private weak var dateOfBirthTexField: CustomTextField!
    @IBOutlet private weak var genderLabel: UILabel!
    
    @IBOutlet private weak var maleButton: UIButton!
    @IBOutlet private weak var femaleButton: UIButton!
    @IBOutlet private weak var otherButton: UIButton!
    @IBOutlet private weak var saveButton: DarkButton!
    
    @IBOutlet private var radioButtons: [UIButton]!
    @IBOutlet weak var delegate: SettingsProfileInfoViewDelegate?
    
    private let validation = ValidationManager()
    private let addressFormatter = AddressFormatter()
    private let datePicker = UIDatePicker()
    private var selectedTimestamp: Double?
    private var latitude: Float?
    private var longitude: Float?
    private var placeId: String?
    private var selectedAddress: AddressModel?
    private var selectedDate: Date? = nil
    private lazy var profileManager: RestProfileManager = RestService.shared.createOperationsManager(from: self, type: RestProfileManager.self)
    
    public var user: UserModel? {
        didSet { fillData() }
    }
    
    public var updatedImage: UIImage? {
        didSet { updateAvatar() }
    }

    public var needRemoveAvatar: Bool = false {
        didSet {
            if needRemoveAvatar {
                updatePhotoAfterRemove()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }
    
    private func initView() {
        loadFromXib(R.nib.settingsProfileInfoView.name, contextOf: SettingsProfileInfoView.self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setTexts()
        
        dateOfBirthTexField.delegate = self
        addressTexField.delegate = self
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(timePickerDidTap), for: .valueChanged)
        dateOfBirthTexField.inputView = datePicker
    }
    
    public func updatePhotoAfterRemove() {
        avatarView.updateWith(image: nil, fullName: user?.profile.fullName ?? "")
    }
    
    // MARK: - Private actions
    @IBAction private func changePhotoButtonDidTap(_ sender: UIButton) {
        delegate?.profileInfoViewChangeImage()
    }
    
    @IBAction private func genderButtonDidSelect(_ sender: UIButton) {
        radioButtons.forEach { $0.setImage(R.image.radio_button_inactive(), for: .normal)}
        sender.setImage(R.image.radio_button_active(), for: .normal)
    }
    
    @IBAction private func saveButtonDidTap(_ sender: UIButton) {
        save()
    }
    
    // MARK: - UI confidurations
    private func setTexts() {
        fullNameTextField.title = R.string.localizable.fullNameTitle()
        addressTexField.title = R.string.localizable.addressTitle()
        dateOfBirthTexField.title = R.string.localizable.birthdayTitle()
        genderLabel.text = R.string.localizable.genderTitle()
        saveButton.setTitle(R.string.localizable.saveButtonTitle(), for: .normal)
    }
    
    private func defineSelectedButton() -> UserGenderType {
        for (index, button) in radioButtons.enumerated() {
            if button.currentImage == R.image.radio_button_active() {
                return UserGenderType.allCases[index]
            }
        }
        
        return .notSelected
    }
    
    private func defineUserGenderButton(_ gender: UserGenderType?) {
        switch gender {
        case .male:
            maleButton.setImage(R.image.radio_button_active(), for: .normal)
            [femaleButton, otherButton].forEach { $0?.setImage(R.image.radio_button_inactive(), for: .normal) }
        case .female:
            femaleButton.setImage(R.image.radio_button_active(), for: .normal)
            [maleButton, otherButton].forEach { $0?.setImage(R.image.radio_button_inactive(), for: .normal) }
        case .other:
            otherButton.setImage(R.image.radio_button_active(), for: .normal)
            [femaleButton, maleButton].forEach { $0?.setImage(R.image.radio_button_inactive(), for: .normal) }
        default:
            maleButton.setImage(R.image.radio_button_active(), for: .normal)
            [maleButton, femaleButton, otherButton].forEach { $0?.setImage(R.image.radio_button_inactive(), for: .normal) }
        }
    }
    
    private func updateAvatar() {
        avatarView.updateWith(image: updatedImage, fullName: user?.profile.fullName ?? "")
    }
    
    @objc private func timePickerDidTap(_ datePicker: UIDatePicker) {
        selectedTimestamp = datePicker.date.timeIntervalSince1970
        selectedDate = datePicker.date
        dateOfBirthTexField?.text = datePicker.date.fullDateString
    }
}

extension SettingsProfileInfoView {
    private func fillData() {
        guard let userProfile = user?.profile else {
            return
        }
        
        fullNameTextField.text = userProfile.fullName
        addressTexField.text = userProfile.address
        defineUserGenderButton(userProfile.gender)
        placeId = userProfile.placeId

        avatarView.updateWith(imageURL: userProfile.avatar?.formatted?.medium, fullName: userProfile.fullName)
        
        if userProfile.birthday != nil, let date = userProfile.birthday {
            selectedDate = date
            dateOfBirthTexField.text = date.fullDateString
        }
    }
    
    private func save() {
        guard valid() else {
            return
        }
        
        var publicAddress = addressTexField?.text
        
        if let addressWithoutHouse = addressTexField?.text?.components(separatedBy: " ").first {
            publicAddress = addressTexField?.text?.deletingPrefix(addressWithoutHouse)
        }
        
        let updateData = UpdateProfileData(fullName: fullNameTextField.text,
                                           address: addressTexField?.text,
                                           publicAddress: publicAddress,
                                           placeId: placeId,
                                           gender: defineSelectedButton(),
                                           longitude: longitude,
                                           latitude: latitude,
                                           birthday: selectedDate,
                                           seeBusinessPosts: user?.profile.seeBusinessPosts ?? true)
        
        restUpdateProfile(data: updateData, image: updatedImage)
    }
    
    private func valid() -> Bool {
        var valid = true
        
        [fullNameTextField, addressTexField, dateOfBirthTexField].forEach { $0?.error = nil }
        
        if let validationError = validation
            .validateFullName(value: fullNameTextField.text)
            .errorMessage(field: R.string.localizable.fullNameTitle()) {
            fullNameTextField.error = validationError.capitalizingFirstLetter()
            valid = false
        }
        
        if addressTexField?.text != user?.profile.address {
            if let validationError = validation
                .validateAddress(value: selectedAddress?.city)
                .errorMessage(field: R.string.localizable.addressTitle()) {
                addressTexField?.error = validationError.capitalizingFirstLetter()
                valid = false
            }
        }
        
        if dateOfBirthTexField.text != "", let selectedBirthday = selectedDate, selectedBirthday > Date() {
            valid = false
            dateOfBirthTexField.error = ValidationErrors().dateTooBig(field: R.string.localizable.birthdayTitle(), date: Date())
        }
        
        return valid
    }
    
    private func openGoogleAddressScreen() {
        guard let presenter = delegate?.profileInfoViewPresenter() else {
            return
        }
        
        presenter.navigationController?.isNavigationBarHidden = true
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
        searchController.searchBar.text = addressTexField.text
        searchController.searchBar.delegate = self
        
        let subView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 350.0, height: 45.0))
        
        subView.addSubview(searchController.searchBar)
        autocompleteController.view.addSubview(subView)
        autocompleteController.view.bringSubviewToFront(subView)
        searchController.searchBar.sizeToFit()
        searchController.hidesNavigationBarDuringPresentation = false
        
        presenter.definesPresentationContext = true
        presenter.present(searchController, animated: true, completion: nil)
    }

    private func profileUpdated() {
        delegate?.goToBasicProfile()
        Toast.show(message: R.string.localizable.successfullyUpdatedProfile())
    }
    
    private func restUpdateProfile(data: UpdateProfileData, image: UIImage?) {
        profileManager.changeUserProfile(data: data, image: image)
            .onStateChanged { [weak self] (state) in
                switch state {
                case .started:
                    self?.saveButton.isLoading = true
                case .ended:
                    if !(self?.needRemoveAvatar ?? false) {
                        self?.saveButton.isLoading = false
                    }
                }
        } .onError { [weak self] (error) in
            self?.handleError(error)
        } .onComplete {  [weak self] (_) in
            guard let self = self else {
                return
            }
            if self.needRemoveAvatar {
                self.restRemoveAvatar()
                return
            }
            self.profileUpdated()
        } .run()
    }

    func restRemoveAvatar() {
        profileManager.removeUserAvatar()
            .onStateChanged({ [weak self] (state) in
                if state == .ended {
                    self?.saveButton.isLoading = false
                }
            })
            .onError { (error) in
                self.handleError(error)
        } .onComplete { [weak self] (_) in
            self?.profileUpdated()
        } .run()
    }
}

// MARK: - UITextFieldDelegate
extension SettingsProfileInfoView: GBKSoftTextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == addressTexField {
            openGoogleAddressScreen()
            return false
        }
        
        return true
    }
    
    func textFieldDidTapButton(_ textField: UITextField) {
        dateOfBirthTexField.becomeFirstResponder()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return textField != dateOfBirthTexField
    }
}

// MARK: - UISearchBarDelegate
extension SettingsProfileInfoView: UISearchBarDelegate {
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        delegate?.profileInfoViewPresenter().navigationController?.isNavigationBarHidden = true
        searchBar.endEditing(true)
    }
}

// MARK: - GMSAutocompleteResultsViewControllerDelegate
extension SettingsProfileInfoView: GMSAutocompleteResultsViewControllerDelegate {
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController, didFailAutocompleteWithError error: Error) {
        // TODO: - Handle error
    }
    
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didAutocompleteWith place: GMSPlace) {
        resultsController.dismiss(animated: true, completion: nil)

        latitude = Float(place.coordinate.latitude)
        longitude = Float(place.coordinate.longitude)
        placeId = place.placeID

        addressTexField.error = nil
        let address = addressFormatter.getAddressFromPlace(place)
        addressTexField.text = address?.addressString
        if let validationError = validation.validateAddress(value: address?.city)
            .errorMessage(field: R.string.localizable.addressTitle()) {
            addressTexField.error = validationError.capitalizingFirstLetter()
            return
        }

        selectedAddress = address
    }
}
