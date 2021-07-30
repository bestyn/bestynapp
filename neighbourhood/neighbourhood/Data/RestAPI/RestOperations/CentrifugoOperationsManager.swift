//
//  CentrifugoOperationsManager.swift
//  neighbourhood
//
//  Created by Dioksa on 13.07.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import GBKSoftRestManager

class CentrifugoOperationsManager: RestOperationsManager {
    func connectionToken() -> PreparedOperation<CentrifugoConnectionModel> {
        let request = Request(url: RestURL.Centrifugo.connect,
                              method: .post,
                              withAuthorization: true)
        return prepare(request: request)
    }
    
    func connectionAuth(_ data: CentrifugoAuthModel) -> PreparedOperation<CentrifugoConnectionModel> {
        let request = Request(
            url: RestURL.Centrifugo.getTokenToPrivate,
            method: .post,
            withAuthorization: true,
            body: data)
        return prepare(request: request)
    }
}


struct CentrifugoAuthModel: Codable {
    let client: String
    let channel: String
}
