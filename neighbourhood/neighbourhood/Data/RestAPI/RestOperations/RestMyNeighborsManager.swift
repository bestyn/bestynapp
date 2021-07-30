//
//  RestMyNeighborsManager.swift
//  neighbourhood
//
//  Created by Dioksa on 12.06.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import GBKSoftRestManager

final class RestMyNeighborsManager: RestOperationsManager {
    func getNeighbors() -> PreparedOperation<[NeighborModel]> {
        let request = Request(
            url: RestURL.MyHeighbors.getNeighbors,
            method: .get,
            withAuthorization: true)
        
        return prepare(request: request)
    }
}
