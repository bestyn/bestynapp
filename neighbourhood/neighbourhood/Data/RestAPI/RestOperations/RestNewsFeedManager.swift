//
//  RestNewsFeedManager.swift
//  neighbourhood
//
//  Created by Andrii Zakhliupanyi on 11.08.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import UIKit
import GBKSoftRestManager

final class RestNewsFeedManager: RestOperationsManager {
    func getNewsFeed(page: Int) -> PreparedOperation<[NewsModel]> {
        
        let query: [String: Any] = ["page": page]
        
        let request = Request(
            url: RestURL.News.newsFeed,
            method: .get,
            query: query,
            withAuthorization: true)
        
        return prepare(request: request)
    }
}
