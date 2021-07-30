//
//  UserModel+Extension.swift
//  neighbourhood
//
//  Created by Artem Korzh on 10.11.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

extension UserModel {

    func profile(id: Int) -> SelectorProfileModel? {
        if profile.id == id {
            return profile.selectorProfile
        }
        return businessProfiles?.first(where: {$0.id == id})?.selectorProfile
    }
}
