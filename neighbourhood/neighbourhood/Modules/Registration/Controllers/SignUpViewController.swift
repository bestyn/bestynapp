//
//  SignUpViewController.swift
//  neighbourhood
//
//  Created by Dioksa on 24.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import GBKSoftTextField

private let staticRowHeight: CGFloat = 28.0
private let maxRowCount: CGFloat = 5.0

final class SignUpViewController: BaseViewController, EmailVerification {
    @IBOutlet private weak var screenTitleLabel: UILabel!
    @IBOutlet private weak var agreeTitleLabel: UILabel!
    @IBOutlet private weak var andWordLabel: UILabel!
    
    @IBOutlet private weak var locationTextField: CustomTextField!
    @IBOutlet private weak var fullNameTextField: CustomTextField!
    @IBOutlet private weak var emailTextField: CustomTextField!
    
    @IBOutlet private weak var passwordTextField: CustomTextField!
    @IBOutlet private weak var confirmPasswordTextField: CustomTextField!
    
    @IBOutlet private weak var signUpButton: DarkButton!
    @IBOutlet private weak var termsButton: UIButton!
    @IBOutlet private weak var privacyButton: UIButton!
    
    private var agreed: Bool = false
    private let addressFormatter = AddressFormatter()
    private let validation = ValidationManager()
    private var locationManager = CLLocationManager()
    private lazy var registrationManager: RestRegistrationManager = RestService.shared.createOperationsManager(from: self, type: RestRegistrationManager.self)
    private lazy var categoriesManager: RestCategoriesManager = RestService.shared.createOperationsManager(from: self, type: RestCategoriesManager.self)
    
    private var latitude: Float?
    private var longitude: Float?
    private var placeId: String?
    private var selectedAddress: AddressModel?
    
    private var selectedCategories = [CategoriesData]()
    private var categories: [CategoriesData]?
    
    private var securePassword = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTexts()
        configureLocationManager()
    }
    
    override func setupViewUI() {
        view.backgroundColor = R.color.greyBackground()
    }
    
    override var isNavigationBarVisible: Bool {
        return false
    }
    
    // MARK: - Private actions
    @IBAction private func didTapSignUp(_ sender: Any) {
        signUp()
    }
    
    @IBAction private func didTapTerms(_ sender: Any) {
        SupportRouter(in: navigationController).openPage(type: .terms)
    }
    
    @IBAction private func didTapPolicy(_ sender: Any) {
        SupportRouter(in: navigationController).openPage(type: .policy)
    }
    
    private func signUp() {
        guard formIsValid() else {
            return
        }
        
        guard let fullName = fullNameTextField.text,
            let email = emailTextField.text,
            let placeId = self.placeId,
            let password = passwordTextField.text else {
                return
        }

        let data = SignUpData(placeId: placeId,
                              fullName: fullName,
                              email: email,
                              password: password)
        restSignUp(data: data)
    }
    
    // MARK: - Validation
    private func formIsValid() -> Bool {
        var valid = true
        
        [fullNameTextField, emailTextField, passwordTextField, confirmPasswordTextField].forEach { $0?.error = nil }
        
        if let validationError = validation
            .validateFullName(value: fullNameTextField.text)
            .errorMessage(field: R.string.localizable.fullNameTitle()) {
            fullNameTextField.error = validationError.capitalizingFirstLetter()
            valid = false
        }
        
        if let validationError = validation
            .validateEmail(value: emailTextField.text)
            .errorMessage(field: R.string.localizable.emailTitle()) {
            emailTextField.error = validationError.capitalizingFirstLetter()
            valid = false
        }
        
        if let validationError = validation
            .validatePassword(value: passwordTextField.text)
            .errorMessage(field: R.string.localizable.passwordTitle()) {
            passwordTextField.error = validationError.capitalizingFirstLetter()
            valid = false
        }
        
        if let validationError = validation
            .validateConfirmPassword(value: confirmPasswordTextField.text, compareTo: passwordTextField.text)
            .errorMessage(field: R.string.localizable.confirmPasswordTitle(), compareField: R.string.localizable.passwordTitle()) {
            confirmPasswordTextField.error = validationError.capitalizingFirstLetter()
            valid = false
        }
        
        if valid && !agreed {
            Toast.show(message: Alert.Message.termsAndPrivacyRequired)
            valid = false
        }
        
        if valid && !validation.checkInternetConnection() {
            Toast.show(message: R.string.localizable.internetConnectionError())
        }
        
        return valid
    }
}

// MARK: - REST requests
extension SignUpViewController {
    private func restSignUp(data: SignUpData) {
        registrationManager.signUp(signUpData: data)
            .onStateChanged { [weak self] (state) in
                switch state {
                case .started:
                    self?.signUpButton.isLoading = true
                case .ended:
                    self?.signUpButton.isLoading = false
                }
        } .onComplete { [weak self] (result) in
            guard let self = self else {
                return
            }
            AnalyticsService.logSignUp()
            self.showEmailVerificationMessage(email: data.email, title: Alert.Title.confirmEmail)
        } .onError { (error) in
            switch error {
            case .processingError(_, let restError):
                var formRelated = false
                guard let info = restError?.result else {
                    fallthrough
                }
                for field in info {
                    if field.field == R.string.localizable.emailTitle() {
                        self.emailTextField.error = field.message
                        formRelated = true
                    }
                }
                if !formRelated {
                    fallthrough
                }
            default:
                self.handleError(error)
            }
        } .run()
    }
}

// MARK: - Configurations
private extension SignUpViewController {
    func configureTexts() {
        screenTitleLabel.text = R.string.localizable.signUp()
        signUpButton.setTitle(R.string.localizable.signUp(), for: .normal)
        
        locationTextField.title = R.string.localizable.addressTitle()
        locationTextField.placeholder = R.string.localizable.addressTitle()
        
        fullNameTextField.title = R.string.localizable.fullNameTitle()
        fullNameTextField.placeholder = R.string.localizable.fullNamePlaceholder()
        
        emailTextField.title = R.string.localizable.emailTitle()
        emailTextField.placeholder = R.string.localizable.enterEmailPlaceholder()
        
        passwordTextField.title = R.string.localizable.passwordTitle()
        passwordTextField.placeholder = R.string.localizable.createPasswordPlaceholder()
        
        confirmPasswordTextField.title = R.string.localizable.confirmPasswordTitle()
        confirmPasswordTextField.placeholder = R.string.localizable.confirmPasswordTitle()
    }
    
    func configureLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        if CLLocationManager.authorizationStatus() == .authorizedAlways ||
        CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
}

// MARK: - CheckBoxViewDelegate
extension SignUpViewController: CheckBoxViewDelegate {
    func checkBoxDidChange(checkBox: CheckBoxView, isChecked: Bool) {
        agreed = isChecked
    }
}

// MARK: - GMSAutocompleteResultsViewControllerDelegate
extension SignUpViewController: GMSAutocompleteResultsViewControllerDelegate {
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController, didFailAutocompleteWithError error: Error) {
        // TODO: - Handle error
    }
    
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didAutocompleteWith place: GMSPlace) {
        resultsController.dismiss(animated: true, completion: nil)

        latitude = Float(place.coordinate.latitude)
        longitude = Float(place.coordinate.longitude)
        placeId = place.placeID

        locationTextField.error = nil
        let address = addressFormatter.getAddressFromPlace(place)
        locationTextField.text = address?.addressString

        if let validationError = validation.validateAddress(value: address?.city)
            .errorMessage(field: R.string.localizable.addressTitle()) {
            locationTextField.error = validationError.capitalizingFirstLetter()
            return
        }
        selectedAddress = address
    }
}

// MARK: - UISearchBarDelegate
extension SignUpViewController: UISearchBarDelegate {
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        navigationController?.isNavigationBarHidden = false
        searchBar.endEditing(true)
    }
}

// MARK: - CLLocationManagerDelegate
extension SignUpViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways || status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let userLocation = locations.last {
            
            latitude = Float(userLocation.coordinate.latitude)
            longitude = Float(userLocation.coordinate.longitude)
            locationManager.stopUpdatingLocation()

            addressFormatter.getAddressFromCoordinates(userLocation.coordinate) { [weak self] (address) in
                self?.selectedAddress = address
                self?.locationTextField.text = address?.addressString
            }

            getPlaceIdFromCoordinates()
        }

    }
    
    private func getPlaceIdFromCoordinates() {
        guard let latitude = self.latitude,
            let longitude = self.longitude else {
                return
        }
        registrationManager.getPlaceId(latitude: latitude, longitude: longitude) { [weak self] (result) in
            self?.placeId = result
        }
    }
}

// MARK: - GBKSoftTextFieldDelegate
extension SignUpViewController: GBKSoftTextFieldDelegate {
    func textFieldDidTapButton(_ textField: UITextField) {
        securePassword = !securePassword
        secureTextField(textField, secure: securePassword)
    }
    
    private func secureTextField(_ textField: UITextField, secure: Bool) {
        if textField == passwordTextField {
            passwordTextField.buttonImage = secure ? R.image.password_eye_hidden() : R.image.password_eye()
            passwordTextField.isSecureTextEntry = secure
        } else if textField == confirmPasswordTextField {
            confirmPasswordTextField.buttonImage = secure ? R.image.password_eye_hidden() : R.image.password_eye()
            confirmPasswordTextField.isSecureTextEntry = secure
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case locationTextField:
            fullNameTextField.becomeFirstResponder()
        case fullNameTextField:
            emailTextField.becomeFirstResponder()
        case emailTextField:
            passwordTextField.becomeFirstResponder()
        case passwordTextField:
            confirmPasswordTextField.becomeFirstResponder()
        default:
            view.endEditing(true)
        }
        
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == locationTextField {
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
            searchController.searchBar.text = locationTextField.text
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
