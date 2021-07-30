//
//  PostRestModel.swift
//  neighbourhood
//
//  Created by Dioksa on 25.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

struct PostData: Codable {
    let description: String
    var address: String? = nil
    var placeId: String? = nil
    var price: Double? = nil
    var name: String? = nil
    var startDatetime: Double? = nil
    var endDatetime: Double? = nil
    var latitude: Float? = nil
    var longitude: Float? = nil
}


struct PostMediaData {
    let mediaToUpload: [PostFormMedia]
    let mediaToDelete: [MediaDataModel]
}
