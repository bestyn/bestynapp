//
//  UserService.swift
//  neighbourhood
//
//  Created by Dioksa on 28.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

class UserService: ErrorHandling {

    static let shared = UserService()
    private init() {}

    var token: TokenModel? {
        return ArchiveService.shared.tokenModel
    }
}
