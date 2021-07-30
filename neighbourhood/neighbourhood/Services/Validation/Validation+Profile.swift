//
//  Validation+Profile.swift
//  neighbourhood
//
//  Created by Dioksa on 23.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import UIKit

extension ValidationManager {

    func validateRequired(value: String?) -> ValidationResult {
        return validate(value: value, rules: [.required, .tooLong(max: 255)])
    }
    
    func validateFullName(value: String?) -> ValidationResult {
        return validate(value: value, rules: [.required, .tooShort(min: 2), .tooLong(max: 50)])
    }

    func validateEmail(value: String?) -> ValidationResult {
        return validate(value: value, rules: [.required, .email, .tooLong(max: 255)])
    }
    
    func validateDescription(value: String?) -> ValidationResult {
        return validate(value: value, rules: [.required, .tooShort(min: 10), .tooLong(max: 200)])
    }
    
    func validatePostDescription(value: String?) -> ValidationResult {
        return validate(value: value, rules: [.required, .tooShort(min: 2), .tooLong(max: 10000)])
    }

    func validateStoryDescription(value: String?) -> ValidationResult {
        return validate(value: value, rules: [.tooShort(min: 2), .tooLong(max: 300)])
    }
    
    func validateEventName(value: String?) -> ValidationResult {
        return validate(value: value, rules: [.required, .tooShort(min: 2), .tooLong(max: 100)])
    }

    func validateInterests(value: [HashtagModel]) -> ValidationResult {
        if value.isEmpty {
            return validate(value: nil, rules: [.required])
        } else {
            return .success
        }
    }
    
    func validateAddedInterests(value: [HashtagModel]) -> ValidationResult {
        if value.isEmpty {
            return validate(value: nil, rules: [.required])
        } else {
            return .success
        }
    }

    func validateCurrentPassword(value: String?) -> ValidationResult {
        return validate(value: value, rules: [.required, .tooShort(min: 8), .tooLong(max: 255)])
    }
    
    func validatePassword(value: String?) -> ValidationResult {
        return validate(value: value, rules: [.required, .tooShort(min: 8), .tooLong(max: 255)])
    }
    
    func validateNewPassword(value: String?, oldValue: String?) -> ValidationResult {
        return validate(value: value, rules: [.required, .tooShort(min: 8), .tooLong(max: 255), .samePassword(to: oldValue ?? "")])
    }

    func validateConfirmPassword(value: String?, compareTo: String?) -> ValidationResult {
        return validate(value: value, rules: [.required, .equal(to: compareTo ?? "")])
    }

    func validatePhone(value: String?) -> ValidationResult {
        return validate(value: value, rules: [.tooLong(max: 10)])
    }

    func validatePhoneCode(value: String?) -> ValidationResult {
        return validate(value: value, rules: [.required, .numbersOnly, .tooShort(min: 6)])
    }

    func validateCardYear(value: String?) -> ValidationResult {
        let currentYear = Calendar.current.component(.year, from: Date())
        return validate(value: value, rules: [.required, .numbersOnly, .numberTooSmall(value: 1980), .numberTooBig(value: currentYear)])
    }
    
    func validateAddress(value: String?) -> ValidationResult {
        return validate(value: value, rules: [.address])
    }
    
    func validatePrice(value: String?) -> ValidationResult {
        return validate(value: value, rules: [.required, .decimal, .numberTooSmall(value: 1), .numberTooBig(value: 1000000000)])
    }
    
    func validateMessageText(value: String?) -> ValidationResult {
        return validate(value: value, rules: [.tooLong(max: 1000)])
    }
    
    func validatePrivateMessageText(value: String?) -> ValidationResult {
        return validate(value: value, rules: [.tooLong(max: 10000)])
    }
}
