//
//  NewsModel.swift
//  neighbourhood
//
//  Created by Andrii Zakhliupanyi on 11.08.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

struct NewsModel: Codable {
    let id: Int
    let description: String
    let url: URL?
    let image: URL?
}
