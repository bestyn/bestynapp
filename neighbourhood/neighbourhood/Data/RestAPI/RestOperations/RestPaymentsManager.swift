//
//  RestPaymentsManager.swift
//  neighbourhood
//
//  Created by Artem Korzh on 19.08.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import GBKSoftRestManager

class RestPaymentsManager: RestOperationsManager {

    func getCurrentPlan() -> PreparedOperation<PaymentPlanModel> {
        let request = Request(url: RestURL.Payments.inAppPayment, method: .get, withAuthorization: true)
        return prepare(request: request)
    }

    func updatePlan(data: PaymentData) -> PreparedOperation<PaymentPlanModel> {
        let request = Request(url: RestURL.Payments.inAppPayment, method: .post, withAuthorization: true, body: data)
        return prepare(request: request)
    }

    func cancelSubscription() -> PreparedOperation<Empty> {
        let request = Request(url: RestURL.Payments.inAppPayment, method: .delete, withAuthorization: true)
        return prepare(request: request)
    }
}
