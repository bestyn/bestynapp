//
//  ForgotPasswordViewController.swift
//  neighbourhood
//
//  Created by Dioksa on 24.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

final class ForgotPasswordViewController: BaseViewController, EmailVerification {
    @IBOutlet private weak var screenTitle: UILabel!
    @IBOutlet private weak var emailTextField: CustomTextField!
    @IBOutlet private weak var submitButton: DarkButton!
    
    private lazy var authorizationManager: RestAuthorizationManager = RestService.shared.createOperationsManager(from: self, type: RestAuthorizationManager.self)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTexts()
    }
    
    override var isNavigationBarVisible: Bool {
        return false
    }
    
    // MARK: - Private actions
    @IBAction private func didTapSubmit(_ sender: Any) {
        restorePassword()
    }
}

// MARK: - Configurations
private extension ForgotPasswordViewController {
    func configureTexts() {
        screenTitle.text = R.string.localizable.forgotPasswordTitle()
        emailTextField.title = R.string.localizable.emailTitle()
        emailTextField.placeholder = R.string.localizable.enterEmailPlaceholder()
        submitButton.setTitle(R.string.localizable.resetPasswordButtonTitle(), for: .normal)
    }
}

// MARK: - Validation and REST request
private extension ForgotPasswordViewController {
    func restorePassword() {
        guard formIsValid(), let email = emailTextField.text else {
            return
        }
        
        submitButton.isLoading = true
        restRestorePassword(email: email) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.submitButton.isLoading = false
        }
    }
    
    func formIsValid() -> Bool {
        var valid = true
        let validation = ValidationManager()
        emailTextField.error = nil
        
        if let validationError = validation
            .validateEmail(value: emailTextField.text)
            .errorMessage(field: R.string.localizable.emailTitle()) {
            emailTextField.error = validationError.capitalizingFirstLetter()
            valid = false
        }
        
        if valid && !validation.checkInternetConnection() {
            Toast.show(message: R.string.localizable.internetConnectionError())
        }
        
        return valid
    }
    
    func restRestorePassword(email: String, completion: @escaping () -> Void) {
        authorizationManager.forgotPassword(email: email)
            .onStateChanged { [weak self] (state) in
                switch state {
                case .started:
                    self?.submitButton.isLoading = true
                case .ended:
                    self?.submitButton.isLoading = false
                    self?.submitButton.setTitle(R.string.localizable.resetPasswordButtonTitle(), for: .normal)
                }
        }
            .onComplete { [weak self] (result) in
                guard let self = self else {
                    return
                }
                completion()
                self.showRestorePasswordMessage()
        } .onError { [weak self] (error) in
            self?.handleError(error)
        } .run()
    }
}

// MARK: - UITextFieldDelegate
extension ForgotPasswordViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
}
