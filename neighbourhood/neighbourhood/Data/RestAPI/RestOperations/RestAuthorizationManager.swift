//
//  RestAuthorizationManager.swift
//  neighbourhood
//
//  Created by Dioksa on 28.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import GBKSoftRestManager

final class RestAuthorizationManager: RestOperationsManager {
    func signIn(data: LoginData) -> PreparedOperation<TokenModel> {

        let request = Request(
            url: RestURL.User.signIn,
            method: .post,
            body: data)

        return prepare(request: request)
    }
    
    func forgotPassword(email: String) -> PreparedOperation<Empty> {

        let request = Request(
            url: RestURL.User.restorePassword,
            method: .post,
            body: ["email": email])

        return prepare(request: request)
    }
    
    func newPassword(data: NewPasswordData) -> PreparedOperation<Empty> {

        let request = Request(
            url: RestURL.User.newPassword,
            method: .post,
            body: data)

        return prepare(request: request)
    }
    
    func signOut() -> PreparedOperation<Empty> {
        let request = Request(
            url: RestURL.User.signOut,
            method: .post,
            withAuthorization: true)

        return prepare(request: request)
    }

    func refreshAuthToken(with refreshToken: String) -> PreparedOperation<TokenModel> {
        let request = Request(
            url: RestURL.User.refreshToken,
            method: .post,
            body: ["refreshToken": refreshToken]
        )
        return prepare(request: request)
    }
}
