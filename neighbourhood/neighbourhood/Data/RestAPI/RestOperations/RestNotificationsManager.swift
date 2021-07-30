//
//  RestNotificationsManager.swift
//  neighbourhood
//
//  Created by Artem Korzh on 10.11.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import GBKSoftRestManager

class RestNotificationsManager: RestOperationsManager {

    func saveToken(token: String) -> PreparedOperation<Empty> {
        let request = Request(
            url: RestURL.Notifications.saveToken,
            method: .post,
            withAuthorization: true,
            body: ["token": token, "os": "ios"])
        return prepare(request: request)
    }
}
