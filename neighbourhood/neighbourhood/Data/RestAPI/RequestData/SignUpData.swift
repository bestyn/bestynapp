//
//  SignUpData.swift
//  neighbourhood
//
//  Created by Dioksa on 28.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

struct SignUpData: Encodable {
    let placeId: String
    let fullName: String
    let email: String
    let password: String
}
