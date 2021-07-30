//
//  Items.swift
//  neighbourhood
//
//  Created by Andrii Zakhliupanyi on 11.08.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import GBKSoftRestManager

struct Items<T> where T: Codable {
    var items: [T] = []
    var pagination: Pagination? = nil
    var isLoading: Bool
    
    var nextPage: Int {
        (pagination?.currentPage ?? 0) + 1
    }
    
    var canNextPage: Bool {
        guard let pagination = pagination else {
            return true
        }
        return pagination.pageCount > pagination.currentPage
    }
    
    init() {
        items = []
        pagination = nil
        isLoading = false
    }
}
