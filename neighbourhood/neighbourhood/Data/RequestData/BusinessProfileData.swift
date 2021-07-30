//
//  BusinessProfileModel.swift
//  neighbourhood
//
//  Created by Dioksa on 25.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

struct BusinessProfileData: Codable {
    let id: Int?
    let fullName: String
    let description: String
    let address: String
    let publicAddress: String?
    let placeId: String
    let longitude: Float?
    let latitude: Float?
    let radius: LocationRadiusVisibility?
    let hashtagIds: String
    let site: String?
    let email: String?
    let phone: String?
}
