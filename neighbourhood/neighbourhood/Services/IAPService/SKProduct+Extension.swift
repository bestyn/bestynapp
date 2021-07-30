//
//  SKProduct+Extension.swift
//  neighbourhood
//
//  Created by Artem Korzh on 17.07.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import StoreKit

extension SKProduct {

    var regularPrice: String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = self.priceLocale
        return formatter.string(from: self.price)
    }
}
