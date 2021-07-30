//
//  RestSupportManager.swift
//  neighbourhood
//
//  Created by Dioksa on 28.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import GBKSoftRestManager

final class RestSupportManager: RestOperationsManager {
    
    func page(type: PageType) -> PreparedOperation<PageModel> {
        let request = Request(url: RestURL.Support.page(slug: type.slug), method: .get)
        return prepare(request: request)
    }
}
