//
//  RestCategoriesManager.swift
//  neighbourhood
//
//  Created by Dioksa on 29.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import GBKSoftRestManager

final class RestCategoriesManager: RestOperationsManager {
    func getCategories(title: String) -> PreparedOperation<[CategoriesData]> {
        let query: [String: Any] = ["title": title]
        let request = Request(url: RestURL.Categories.categories, method: .get, query: query)

        return prepare(request: request)
    }
    
    func getAllCategories() -> PreparedOperation<[CategoriesData]> {
        
        let request = Request(
            url: RestURL.Categories.categories,
            method: .get,
            withAuthorization: false)
        
        return prepare(request: request)
    }
}
