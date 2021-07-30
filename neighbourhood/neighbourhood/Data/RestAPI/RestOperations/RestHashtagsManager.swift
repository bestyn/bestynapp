//
//  RestHashtagsManager.swift
//  neighbourhood
//
//  Created by Artem Korzh on 16.11.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import GBKSoftRestManager

class RestHashtagsManager: RestOperationsManager {

    func getPopularHastags() -> PreparedOperation<[HashtagModel]> {
        let request = Request(
            url: RestURL.Hashtags.list,
            method: .get,
            query: ["sort": "-featured,-popularity"],
            withAuthorization: true
            )
        return prepare(request: request)
    }

    func searchHashtags(search: String, page: Int) -> PreparedOperation<[HashtagModel]> {
        let request = Request(
            url: RestURL.Hashtags.list,
            method: .get,
            query: ["sort": "-featured,-popularity", "name": search, "page": page],
            withAuthorization: true
            )
        return prepare(request: request)
    }

}
