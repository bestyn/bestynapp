//
//  RestConfig.swift
//  neighbourhood
//
//  Created by Dioksa on 28.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import GBKSoftRestManager

final class RestConfigManager: RestOperationsManager {
    func getConfig() -> PreparedOperation<ConfigModel> {
        let request = Request(url: RestURL.config, method: .get)
        return prepare(request: request)
    }
}
