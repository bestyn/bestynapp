//
//  PaymentData.swift
//  neighbourhood
//
//  Created by Artem Korzh on 19.08.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

struct PaymentData: Encodable {
    let transactionToken: String
    let platform: PaymentPlatform = .ios
    let productName: String
}
