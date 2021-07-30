//
//  SignInViewController.swift
//  neighbourhood
//
//  Created by Dioksa on 24.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import GBKSoftTextField

final class SignInViewController: BaseViewController, EmailVerification {
    @IBOutlet private weak var emailTextField: CustomTextField!
    @IBOutlet private weak var passwordTextField: CustomTextField!
    @IBOutlet private weak var signInButton: DarkButton!
    
    @IBOutlet private weak var screenTitleLabel: UILabel!
    @IBOutlet private weak var createAccountLabel: UILabel!
    @IBOutlet private weak var signUpButton: UIButton!
    @IBOutlet private weak var forgotPasswordButton: UIButton!
    @IBOutlet private weak var signUpBottomView: UIView!
    
    private var securePassword = true
    private lazy var authorizationManager: RestAuthorizationManager = RestService.shared.createOperationsManager(from: self, type: RestAuthorizationManager.self)
    
    public var isNewEmail = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTexts()
        
        if isNewEmail {
            emailTextField.text = ArchiveService.shared.newEmail
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        [emailTextField, passwordTextField].forEach( {$0?.error = nil} )
        signInButton.isLoading = false
    }
    
    override var isBottomPaddingNeeded: Bool {
        return false
    }

    override var isNavigationBarVisible: Bool {
        return false
    }
    
    // MARK: - Private actions
    @IBAction private func signInButtonDidTap(_ sender: UIButton) {
        signIn()
    }
    
    @IBAction private func forgotButtonDidTap(_ sender: UIButton) {
        AuthorizationRouter(in: navigationController).openForgotPasswordScreen()
    }
    
    @IBAction private func signUpButtonDidTap(_ sender: UIButton) {
        RegistrationRouter(in: navigationController).openSignUpScreen()
    }
}

// MARK: - Configurations
private extension SignInViewController {
    func configureTexts() {
        screenTitleLabel.text = R.string.localizable.signIn()
        createAccountLabel.text = R.string.localizable.noAccoutText()
        signUpButton.setTitle(R.string.localizable.signUp(), for: .normal)
        signInButton.setTitle(R.string.localizable.signIn(), for: .normal)
        
        emailTextField.title = R.string.localizable.emailTitle()
        emailTextField.placeholder = R.string.localizable.enterEmailPlaceholder()
        
        passwordTextField.title = R.string.localizable.passwordTitle()
        passwordTextField.placeholder = R.string.localizable.enterPasswordPlaceholder()
        
        forgotPasswordButton.setTitle(R.string.localizable.forgotPasswordButtonTitle(), for: .normal)
    }
}

// MARK: - Validation and REST request
private extension SignInViewController {
    func signIn() {
        guard formIsValid() else {
            return
        }
        
        guard let email = emailTextField.text,
            let password = passwordTextField.text else {
                return
        }
        
        signInButton.isLoading = true
        let loginData = LoginData(email: email, password: password)
        restSignIn(data: loginData)
    }
    
    func formIsValid() -> Bool {
        var valid = true
        let validation = ValidationManager()
        
        [emailTextField, passwordTextField].forEach( {$0?.error = nil} )
        
        if let validationError = validation
            .validateEmail(value: emailTextField.text)
            .errorMessage(field: R.string.localizable.emailTitle()) {
            emailTextField.error = validationError.capitalizingFirstLetter()
            valid = false
        }
        
        if let validationError = validation
            .validateRequired(value: passwordTextField.text)
            .errorMessage(field: R.string.localizable.passwordTitle()) {
            passwordTextField.error = validationError.capitalizingFirstLetter()
            valid = false
        }
        
        if valid && !validation.checkInternetConnection() {
            Toast.show(message: R.string.localizable.internetConnectionError())
        }
        
        return valid
    }
    
    func restSignIn(data: LoginData) {
        authorizationManager.signIn(data: data)
            .onStateChanged { (state) in
                switch state {
                case .started:
                    self.signInButton.isLoading = true
                case .ended:
                    self.signInButton.isLoading = false
                    self.signInButton.setTitle(R.string.localizable.signIn(), for: .normal)
                }
        }.onError { (error) in
            switch error {
            case .processingError(_, let info):
                if let _ = info?.result?.first(where: {$0.code == BackendError.emailNotVerified})?.message {
                    self.showEmailVerificationMessage(email: data.email, title: Alert.Title.notConfirmedEmail, message: Alert.Message.notConfirmedEmail)
                    return
                }
                fallthrough
            default:
                self.handleError(error)
            }
        }.onComplete { (model) in
            ArchiveService.shared.tokenModel = model.result
            RootRouter.shared.openApp()
        }.run()
    }
}

// MARK: - GBKSoftTextFieldDelegate
extension SignInViewController: GBKSoftTextFieldDelegate {
    func textFieldDidTapButton(_ textField: UITextField) {
        securePassword = !securePassword
        secureTextField(secure: securePassword)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case emailTextField:
            passwordTextField.becomeFirstResponder()
        default:
            view.endEditing(true)
        }
        
        return true
    }
    
    private func secureTextField(secure: Bool) {
        passwordTextField.buttonImage = secure ? R.image.password_eye_hidden() : R.image.password_eye()
        passwordTextField.isSecureTextEntry = secure
    }
}
