//
//  ErrorHandling.swift
//  neighbourhood
//
//  Created by Dioksa on 22.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import GBKSoftRestManager

enum BackendError {
    static let emailNotVerified = 1250
    static let subscriptionAlreadyConnected = 1150
}

protocol ErrorHandling {
    func handleError(_ error: Error)
}

extension ErrorHandling {
    func handleError(_ error: Error) {
        guard let apiError = error as? APIError else {
            Toast.show(message: error.localizedDescription)
            return
        }
        handleApiError(apiError)
    }

    private func handleApiError(_ error: APIError) {
        switch error {
        case .unauthorized:
            Toast.show(message: R.string.localizable.invalidCredentialsError())
            RootRouter.shared.exitApp()
        case .serverError(_, _):
            Toast.show(message: Alert.ErrorMessage.serverUnavailable)
        case .processingError(_, let error):
            if error?.message == R.string.localizable.businessAccountsLimitError() {
                Toast.show(message: R.string.localizable.businessAccountsLimitError())
            } else if let message = error?.result?.first?.message ?? error?.message {
                Toast.show(message: message)
            }
        case .executionError(_):
            Toast.show(message: Alert.ErrorMessage.noInternetConnection)
        default:
            break
        }
    }
}
