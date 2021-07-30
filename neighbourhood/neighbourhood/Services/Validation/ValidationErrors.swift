//
//  ValidationErrors.swift
//  neighbourhood
//
//  Created by Dioksa on 23.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

struct ValidationErrors {

    private var config = ArchiveService.shared.config

    private func defaultError(field: String? = nil) -> String {
        if let field = field {
            return String(format: "%@ is invalid", field)
        }
        return "Oops, something went wrong. Please try again"
    }

    public func tooShort(field: String, length: Int) -> String {
        return config.error(code: 1081, replacements: [.attribute(field), .min("\(length)")]) ??
            defaultError(field: field)
    }

    public func tooLong(field: String, length: Int) -> String {
        return config.error(code: 1082, replacements: [.attribute(field), .max("\(length)")]) ??
            defaultError(field: field)
    }

    public func required(field: String) -> String {
        return config.error(code: 1060, replacements: [.attribute(field)]) ??
            defaultError(field: field)
    }

    public func phone(field: String) -> String {
        return config.error(code: 1070, replacements: [.attribute(field)]) ??
            defaultError(field: field)
    }

    public func email(field: String) -> String {
        return config.error(code: 1010, replacements: [.attribute(field)]) ??
            defaultError(field: field)
    }

    public func password(field: String) -> String {
        return config.error(code: 1300, replacements: [.attribute(field)]) ??
            defaultError(field: field)
    }
    
    public func currentPassword(field: String) -> String {
        return config.error(code: 1220, replacements: [.attribute(field)]) ??
            defaultError(field: field)
    }

    public func equal(field: String, compareField: String) -> String {
        return config.error(code: 1110, replacements: [.attribute(field), .comparable(compareField)]) ??
            defaultError(field: field)
    }

    public func samePassword(field: String, oldValue: String) -> String {
        return config.error(code: 1230, replacements: [.attribute(field), .comparable(oldValue)]) ??
            defaultError(field: field)
    }
    
    public func numberOnly(field: String) -> String {
        return config.error(code: 1050, replacements: [.attribute(field)]) ??
            defaultError(field: field)
    }

    public func numberTooSmall(field: String, amount: Int) -> String {
        return config.error(code: 1052, replacements: [.attribute(field), .min("\(amount)")]) ??
            defaultError(field: field)
    }

    public func numberTooBig(field: String, amount: Int) -> String {
        return config.error(code: 1053, replacements: [.attribute(field), .max("\(amount)")]) ??
            defaultError(field: field)
    }
    
    public func addressWithoutHouse() -> String {
        return config.error(code: 1270, replacements: []) ?? defaultError(field: "")
    }

    public func dateTooBig(field: String, date: Date) -> String {
        return config.error(code: 1022, replacements: [.attribute(field), .max("Today")]) ??
                   defaultError(field: field)
    }
    
    public func invalidDate() -> String {
        return "This date and time can not be in the past"
    }
    
    public func profilesCount() -> String {
        return config.error(code: 1340, replacements: []) ?? defaultError(field: "")
    }
    
    public func wrongEndEventDate(field: String, startEventDate: String) -> String {
        return config.error(code: 1311, replacements: [.attribute(field), .max(startEventDate)]) ??
        defaultError(field: field)
    }

    public func dateInThePast(field: String) -> String {
        return config.error(code: 1310, replacements: []) ?? defaultError(field: field)
    }
}
