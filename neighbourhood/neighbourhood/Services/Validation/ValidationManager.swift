//
//  ValidationManager.swift
//  neighbourhood
//
//  Created by Dioksa on 23.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

class ValidationManager {
    
    func checkInternetConnection() -> Bool {
        do {
            try ReachabilityService.shared.checkingConnection()
        } catch {
            return false
        }
        return true
    }
    
    enum ValidationRule {
        case required
        case email
        case phone
        case samePassword(to: String)
        case tooLong(max: Int)
        case tooShort(min: Int)
        case equal(to: String)
        case numbersOnly
        case decimal
        case numberTooSmall(value: Int)
        case numberTooBig(value: Int)
        case address
    }

    enum ValidationResult {
        case success
        case failed(failedRule: ValidationRule)

        func errorMessage(field: String, compareField: String? = nil) -> String? {
            switch self {
            case .success:
                return nil
            case .failed(let failedRule):
                switch failedRule {
                case .required:
                    return ValidationErrors().required(field: field)
                case .tooShort(let min):
                    return ValidationErrors().tooShort(field: field, length: min)
                case .tooLong(let max):
                    return ValidationErrors().tooLong(field: field, length: max)
                case .phone:
                    return ValidationErrors().phone(field: field)
                case .email:
                    return ValidationErrors().email(field: field)
                case .equal(_):
                    return ValidationErrors().equal(field: field, compareField: compareField!)
                case .samePassword(_):
                    return ValidationErrors().samePassword(field: field, oldValue: compareField!)
                case .numbersOnly, .decimal:
                    return ValidationErrors().numberOnly(field: field)
                case .numberTooSmall(let value):
                    return ValidationErrors().numberTooSmall(field: field, amount: value)
                case .numberTooBig(let value):
                    return ValidationErrors().numberTooBig(field: field, amount: value)
                case .address:
                    return ValidationErrors().addressWithoutHouse()
                }
            }
        }
    }

    public func validate(value: String?, rules: [ValidationRule]) -> ValidationResult {
        for rule in rules {
            if isFailedRule(value: value, rule: rule) {
                return ValidationResult.failed(failedRule: rule)
            }
        }

        return ValidationResult.success
    }

    // MARK: - validation
    // swiftlint:disable cyclomatic_complexity
    private func isFailedRule(value: String?, rule: ValidationRule) -> Bool {
        switch rule {
        case .required, .address:
            if value == nil || value!.isEmpty {
                return true
            }
        case .tooShort(let min):
            if let value = value, value.count < min {
                return true
            }
        case .tooLong(let max):
            if let value = value, value.count > max {
                return true
            }
        case .phone:
            if let value = value, value.count > 0 {
                let phoneRegEx = "\\+[0-9]{10,}"
                let predicate = NSPredicate(format: "SELF MATCHES %@", phoneRegEx)
                return !predicate.evaluate(with: value)
            }
        case .email:
            if let value = value, value.count > 0 {
                let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,5}"
                let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
                return !predicate.evaluate(with: value)
            }
        case .equal(let compareValue):
            if let value = value, value.count > 0, value != compareValue {
                return true
            }
        case .samePassword(let oldValue):
            if let value = value, value.count > 0, value == oldValue {
                return true
            }
        case .numbersOnly:
            if let value = value, value.count > 0 {
                if !value.isNumber() {
                    return true
                }
            }
        case .decimal:
            if let value = value, value.count > 0 {
                if !value.isDecimal() {
                    return true
                }
            }
        case .numberTooSmall(let amount):
            if let value = value, let intValue = Int(value) {
                if intValue < amount {
                    return true
                }
            }
        case .numberTooBig(let amount):
            if let value = value, let intValue = Int(value) {
                if intValue > amount {
                    return true
                }
            }
        }
        return false
    }
}
