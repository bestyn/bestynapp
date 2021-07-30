//
//  SettingsChangeEmailView.swift
//  neighbourhood
//
//  Created by Artem Korzh on 08.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

@objc protocol SettingsChangeEmailViewDelegate: class {
    func changeEmailView(didChange email: String)
}

final class SettingsChangeEmailView: UIView, ErrorHandling {
    @IBOutlet private weak var emailTextField: CustomTextField!
    @IBOutlet private weak var newEmailTextField: CustomTextField!
    @IBOutlet private weak var saveButton: DarkButton!
    
    public var email: String? {
        didSet { emailTextField.text = email }
    }
    
    private let validation = ValidationManager()
    
    private lazy var profileManager: RestProfileManager = RestService.shared.createOperationsManager(from: self, type: RestProfileManager.self)
    
    @IBOutlet public weak var delegate: SettingsChangeEmailViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }
    
    private func initView() {
        loadFromXib(R.nib.settingsChangeEmailView.name, contextOf: SettingsChangeEmailView.self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setTexts()
    }
    
    @IBAction private func saveButtonDidTap(_ sender: UIButton) {
        save()
    }
    
    private func setTexts() {
        emailTextField.title = R.string.localizable.existingEmailTitle()
        emailTextField.placeholder = " "
        newEmailTextField.title = R.string.localizable.newEmailTitle()
        newEmailTextField.placeholder = R.string.localizable.newEmailPlaceholder()
        saveButton.setTitle(R.string.localizable.saveButtonTitle(), for: .normal)
    }
    
    // MARK: - REST and validation
    private func save() {
        guard valid() else {
            return
        }
        
        restUpdateEmail(email: newEmailTextField.text!)
    }
    
    private func valid() -> Bool {
        var valid = true
        
        newEmailTextField.error = nil
        
        if let validationError = validation
            .validateEmail(value: newEmailTextField.text)
            .errorMessage(field: R.string.localizable.emailTitle()) {
            newEmailTextField.error = validationError.capitalizingFirstLetter()
            valid = false
        }
        
        return valid
    }
    
    private func restUpdateEmail(email: String ) {
        profileManager.changeProfileEmail(email: email)
            .onStateChanged { [weak self] (state) in
                switch state {
                case .started:
                    self?.saveButton.isLoading = true
                case .ended:
                    self?.saveButton.isLoading = false
                }
        } .onError {  [weak self] (error) in
            self?.handleError(error)
        } .onComplete { [weak self] (result) in
            guard let self = self else {
                return
            }
            
            self.delegate?.changeEmailView(didChange: email)
        } .run()
    }
}
