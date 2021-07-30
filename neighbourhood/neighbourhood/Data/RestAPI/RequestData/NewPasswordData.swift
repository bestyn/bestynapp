//
//  NewPasswordData.swift
//  neighbourhood
//
//  Created by Dioksa on 28.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

struct NewPasswordData: Codable {
    let resetToken: String
    let newPassword: String
    let confirmNewPassword: String
}
