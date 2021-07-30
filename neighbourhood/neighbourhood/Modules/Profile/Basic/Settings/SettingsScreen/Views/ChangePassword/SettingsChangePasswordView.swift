//
//  SettingsChangePasswordView.swift
//  neighbourhood
//
//  Created by Artem Korzh on 08.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import GBKSoftTextField

protocol SettingsChangePasswordViewDelegate: class {
    func goToBasicProfilePage()
}


@IBDesignable
class SettingsChangePasswordView: UIView, ErrorHandling {
    
    @IBOutlet private weak var currentPasswordTextField: CustomTextField!
    @IBOutlet private weak var newPasswordTextField: CustomTextField!
    @IBOutlet private weak var confirmPasswordTextField: CustomTextField!
    @IBOutlet private weak var saveButton: DarkButton!
    
    private var securePassword = true
    private let validation = ValidationManager()
    private lazy var profileManager: RestProfileManager = RestService.shared.createOperationsManager(from: self, type: RestProfileManager.self)
    
    weak var delegate: SettingsChangePasswordViewDelegate?
    
    @IBAction private func saveButtonDidTap(_ sender: UIButton) {
        save()
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
        loadFromXib(R.nib.settingsChangePasswordView.name, contextOf: SettingsChangePasswordView.self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setTexts()
        setDelegates()
    }
    
    private func setDelegates() {
        currentPasswordTextField.delegate = self
        newPasswordTextField.delegate = self
        confirmPasswordTextField.delegate = self
    }
    
    private func setTexts() {
        currentPasswordTextField.title = R.string.localizable.currentPasswordTitle()
        currentPasswordTextField.placeholder = R.string.localizable.currentPasswordTitle()
        
        newPasswordTextField.title = R.string.localizable.newPasswordTitle()
        newPasswordTextField.placeholder = R.string.localizable.createPasswordPlaceholder()
        
        confirmPasswordTextField.title = R.string.localizable.confirmNewPasswordTitle()
        confirmPasswordTextField.placeholder = R.string.localizable.confirmPasswordTitle()
        
        saveButton.setTitle(R.string.localizable.saveButtonTitle(), for: .normal)
    }
    
    private func save() {
        guard valid() else {
            return
        }
        let data = ProfilePasswordData(password: currentPasswordTextField.text!,
                                   newPassword: newPasswordTextField.text!,
                                   confirmPassword: confirmPasswordTextField.text!)
        
        restUpdatePassword(data: data)
    }
    
    private func valid() -> Bool {
        var valid = true
        
        [currentPasswordTextField, newPasswordTextField, confirmPasswordTextField].forEach { $0?.error = nil }
        
        if let validationError = validation
            .validateCurrentPassword(value: currentPasswordTextField.text)
            .errorMessage(field: R.string.localizable.currentPasswordTitle()) {
            currentPasswordTextField.error = validationError.capitalizingFirstLetter()
            valid = false
        }
        
        if let validationError = validation
            .validateNewPassword(value: newPasswordTextField.text, oldValue: currentPasswordTextField.text)
            .errorMessage(field: R.string.localizable.newPasswordTitle(), compareField: R.string.localizable.currentPasswordTitle()) {
            newPasswordTextField.error = validationError.capitalizingFirstLetter()
            valid = false
        }
        
        if let validationError = validation
            .validateConfirmPassword(value: confirmPasswordTextField.text, compareTo: newPasswordTextField.text)
            .errorMessage(field: R.string.localizable.confirmNewPasswordTitle(), compareField: R.string.localizable.newPasswordTitle()) {
            confirmPasswordTextField.error = validationError.capitalizingFirstLetter()
            valid = false
        }
        
        return valid
    }
    
    private func restUpdatePassword(data: ProfilePasswordData) {
        profileManager.changeProfilePassword(data: data)
            .onStateChanged { [weak self] (state) in
                switch state {
                case .started:
                    self?.saveButton.isLoading = true
                case .ended:
                    self?.saveButton.isLoading = false
                }
        } .onComplete {  [weak self] (_) in
            guard let self = self else {
                return
            }
            
            self.delegate?.goToBasicProfilePage()
            Toast.show(message: R.string.localizable.passwordChanged())
            [self.currentPasswordTextField, self.newPasswordTextField, self.confirmPasswordTextField].forEach { $0?.text = nil }
        } .onError { [weak self] (error) in
            self?.handleError(error)
        } .run()
    }
}

// MARK: - GBKSoftTextFieldDelegate
extension SettingsChangePasswordView: GBKSoftTextFieldDelegate {
    func textFieldDidTapButton(_ textField: UITextField) {
        securePassword = !securePassword
        secureTextField(textField, secure: securePassword)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case currentPasswordTextField:
            newPasswordTextField.becomeFirstResponder()
        case newPasswordTextField:
            confirmPasswordTextField.becomeFirstResponder()
        default:
            endEditing(true)
        }
        
        return true
    }
    
    private func secureTextField(_ textField: UITextField, secure: Bool) {
        if textField == currentPasswordTextField {
            currentPasswordTextField.buttonImage = secure ? R.image.password_eye_hidden() : R.image.password_eye()
            currentPasswordTextField.isSecureTextEntry = secure
        } else if textField == newPasswordTextField {
            newPasswordTextField.buttonImage = secure ? R.image.password_eye_hidden() : R.image.password_eye()
            newPasswordTextField.isSecureTextEntry = secure
        } else {
            confirmPasswordTextField.buttonImage = secure ? R.image.password_eye_hidden() : R.image.password_eye()
            confirmPasswordTextField.isSecureTextEntry = secure
        }
    }
}
