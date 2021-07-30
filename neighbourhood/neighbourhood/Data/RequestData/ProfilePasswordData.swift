//
//  ProfilePassword.swift
//  neighbourhood
//
//  Created by Dioksa on 25.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

struct ProfilePasswordData: Codable {
    let password: String
    let newPassword: String
    let confirmPassword: String
}
