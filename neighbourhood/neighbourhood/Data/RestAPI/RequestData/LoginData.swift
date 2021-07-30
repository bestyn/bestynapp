//
//  LoginData.swift
//  neighbourhood
//
//  Created by Dioksa on 30.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

struct LoginData: Encodable {
    let email: String
    let password: String
    let deviceId: String = Configuration.deviceID
}
