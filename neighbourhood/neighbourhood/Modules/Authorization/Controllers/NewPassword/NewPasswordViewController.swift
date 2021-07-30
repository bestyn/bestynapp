//
//  NewPasswordViewController.swift
//  neighbourhood
//
//  Created by Dioksa on 24.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import GBKSoftTextField

final class NewPasswordViewController: BaseViewController {
    @IBOutlet private weak var screenTitle: UILabel!
    @IBOutlet private weak var passwordTextField: CustomTextField!
    @IBOutlet private weak var confirmPasswordTextField: CustomTextField!
    @IBOutlet private weak var submitButton: DarkButton!
    @IBOutlet private weak var goToLabel: UILabel!
    @IBOutlet private weak var signInButton: UIButton!
    
    private let restoreToken: String
    private var securePassword = true
    
    private lazy var authorizationManager: RestAuthorizationManager = RestService.shared.createOperationsManager(from: self, type: RestAuthorizationManager.self)
    
    init(token: String) {
        restoreToken = token
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isBottomPaddingNeeded: Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTexts()
    }
    
    // MARK: - Private actions
    @IBAction private func didTapSignIn(_ sender: Any) {
        AuthorizationRouter(in: self.navigationController).setRootSignInScreen()
    }
    
    @IBAction private func didTapSubmit(_ sender: Any) {
        updatePassword()
    }
}

// MARK: - Configurations
private extension NewPasswordViewController {
    func configureTexts() {
        screenTitle.text = R.string.localizable.resetPasswordButtonTitle()
        
        passwordTextField.title = R.string.localizable.newPasswordTitle()
        passwordTextField.placeholder = R.string.localizable.createPasswordPlaceholder()
        
        confirmPasswordTextField.title = R.string.localizable.confirmNewPasswordTitle()
        confirmPasswordTextField.placeholder = R.string.localizable.confirmNewPasswordTitle()
        
        submitButton.setTitle(R.string.localizable.changePasswordButtonTitle(), for: .normal)
    }
}

// MARK: - Validation and REST request
private extension NewPasswordViewController {
    func updatePassword() {
        guard formIsValid() else {
            return
        }
        
        guard let password = passwordTextField.text,
            let confirmPassword = confirmPasswordTextField.text else {
                return
        }
        
        let newPasswordData = NewPasswordData(resetToken: restoreToken, newPassword: password, confirmNewPassword: confirmPassword)
        
        submitButton.isLoading = true
        restSetNewPassword(data: newPasswordData) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.submitButton.isLoading = false
        }
    }
    
    func formIsValid() -> Bool {
        var valid = true
        let validation = ValidationManager()
        [passwordTextField, confirmPasswordTextField].forEach { $0?.error = nil }
        
        if let validationError = validation
            .validatePassword(value: passwordTextField.text)
            .errorMessage(field: R.string.localizable.newPasswordTitle()) {
            passwordTextField.error = validationError.capitalizingFirstLetter()
            valid = false
        }
        
        if let validationError = validation
            .validateConfirmPassword(value: confirmPasswordTextField.text, compareTo: passwordTextField.text)
            .errorMessage(field: R.string.localizable.confirmNewPasswordTitle(), compareField: R.string.localizable.newPasswordTitle()) {
            confirmPasswordTextField.error = validationError.capitalizingFirstLetter()
            valid = false
        }
        
        if valid && !validation.checkInternetConnection() {
            Toast.show(message: R.string.localizable.internetConnectionError())
        }
        
        return valid
    }
    
    func restSetNewPassword(data: NewPasswordData, completion: @escaping () -> Void) {
        authorizationManager.newPassword(data: data)
            .onComplete { _ in
                completion()
                Alert(title: Alert.Title.passwordChanged, message: Alert.Message.resetPassword)
                    .show { (_) in
                        AuthorizationRouter(in: self.navigationController).setRootSignInScreen()
                }
        } .onError { [weak self] (error) in
            self?.handleError(error)
        } .run()
    }
}

// MARK: - GBKSoftTextFieldDelegate
extension NewPasswordViewController: GBKSoftTextFieldDelegate {
    func textFieldDidTapButton(_ textField: UITextField) {
        securePassword = !securePassword
        secureTextField(textField, secure: securePassword)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case passwordTextField:
            confirmPasswordTextField.becomeFirstResponder()
        default:
            view.endEditing(true)
        }
        
        return true
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
}
