//
//  SubscriptionsManager.swift
//  neighbourhood
//
//  Created by Artem Korzh on 20.08.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

enum SubscriptionProcess {
    case fetchAvailableSubscriptions
    case subscribe
    case unsubscribe
    case getCurrentSubscription
    case restorePurchases
    case checkCurrentSubscription
}

protocol SubscriptionsManagerDelegate: class {
    func availableSubscriptionsUpdated(_ subscriptions: [IAPProductModel])
    func currentSubscriptionReceived(_ currentSubscription: PaymentPlanModel?)
    func subscriptionProcessBegan(_ process: SubscriptionProcess)
    func subscriptionProcessEnd(_ process: SubscriptionProcess?)
    func subscriptionProcessEndWithCancel(_ process: SubscriptionProcess?)
    func subscriptionProcessFailed(_ process: SubscriptionProcess?, with error: Error)
}

class SubscriptionsManager {

    static let shared = SubscriptionsManager()

    private init() {
        IAPService.shared.delegate = self
    }

    public weak var delegate: SubscriptionsManagerDelegate?

    private(set) var currentSubscription: PaymentPlanModel?
    private(set) var restoredSubscription: PaymentPlanModel?
    private var restoredTransactionID: String?
    private var currentProcess: SubscriptionProcess?
    
    private lazy var restPaymentsManager: RestPaymentsManager = RestService.shared.createOperationsManager(from: self, type: RestPaymentsManager.self)

    public func getAvailableSubscriptions() {
        currentProcess = .fetchAvailableSubscriptions
        delegate?.subscriptionProcessBegan(.fetchAvailableSubscriptions)
        IAPService.shared.fetchProducts(productIDs: ArchiveService.shared.config.inAppProductItems)
    }

    public func subscribe(subscriptionID: String) {
        guard subscriptionID != currentSubscription?.productName else {
            return
        }
        restoredTransactionID = nil
        restoredSubscription = nil
        currentProcess = .subscribe
        delegate?.subscriptionProcessBegan(.subscribe)
        IAPService.shared.purchase(productID: subscriptionID)
    }

    public func getCurrentSubscription() {
        currentProcess = .getCurrentSubscription
        delegate?.subscriptionProcessBegan(.getCurrentSubscription)
        restGetCurrentPaymentPlan()
    }

    public func checkCurrentSubscription() {
        currentProcess = .checkCurrentSubscription
        delegate?.subscriptionProcessBegan(.checkCurrentSubscription)
        if currentSubscription != nil {
            actualizeSubscription()
        } else {
            restGetCurrentPaymentPlan {
                self.actualizeSubscription()
            }
        }
    }

    public func restoreSubscriptions() {
        restoredTransactionID = nil
        restoredSubscription = nil
        currentProcess = .restorePurchases
        delegate?.subscriptionProcessBegan(.restorePurchases)
        IAPService.shared.restorePurchases()
    }

    public func reset() {
        currentSubscription = nil
        currentProcess = nil
        delegate = nil
        restoredTransactionID = nil
    }

    private func actualizeSubscription() {
        if let receipt = IAPService.shared.getReceipt() {
            let validationResult = IAPReceiptValidator().validate(receiptData: receipt.data)
            switch validationResult {
            case .success(let parsedReceipt):
                guard let receipts = parsedReceipt.inAppPurchaseReceipts else {
                    return
                }
                let sortedReceipts = receipts.sorted(by: { (a, b) -> Bool in
                    guard let firstDate = a.subscriptionExpirationDate, let secondDate = b.subscriptionExpirationDate else {
                        return false
                    }
                    return firstDate > secondDate
                })
                if let currentSubscription = currentSubscription {
                    guard let actualSubscription = sortedReceipts.first(where: {$0.originalTransactionIdentifier
                        == currentSubscription.transactionToken}) else {
                        delegate?.subscriptionProcessEnd(.checkCurrentSubscription)
                        return
                    }
                    if let expirationDate = actualSubscription.subscriptionExpirationDate, expirationDate < Date() {
                        delegate?.subscriptionProcessBegan(.unsubscribe)
                        restRemovePaymentPlan()
                    }
                } else {
                     if let lastSubscription = sortedReceipts.first,
                        let expirationDate = lastSubscription.subscriptionExpirationDate,
                        expirationDate > Date(),
                        let transactionID = lastSubscription.originalTransactionIdentifier, let productID = lastSubscription.productIdentifier {
                        delegate?.subscriptionProcessBegan(.subscribe)
                        restUpdatePaymentPlan(data: PaymentData(transactionToken: transactionID, productName: productID))
                    }
                }
                delegate?.subscriptionProcessEnd(.checkCurrentSubscription)
            case .error(let error):
                delegate?.subscriptionProcessFailed(.subscribe, with: error)
            }
        }
    }
}

// MARK: - IAPServiceDelegate

extension SubscriptionsManager: IAPServiceDelegate {
    func iap(availableProducts: [IAPProductModel]) {
        let products = availableProducts.sorted(by: {$0.price < $1.price})
        delegate?.availableSubscriptionsUpdated(products)
        delegate?.subscriptionProcessEnd(.fetchAvailableSubscriptions)
    }

    func iap(didFailWithError error: Error) {
        delegate?.subscriptionProcessFailed(currentProcess, with: error)
        delegate?.subscriptionProcessEnd(currentProcess)
    }

    func iap(transationCompleteID transactionID: String, currentTransactionID: String, productID: String, receipt: PaymentReceipt) {
        let validationResult = IAPReceiptValidator().validate(receiptData: receipt.data)
        switch validationResult {
        case .success(let parsedReceipt):
            DispatchQueue(label: "purchases").sync {
                if self.restoredTransactionID != nil || self.restoredSubscription != nil {
                    return
                }
                guard let receipts = parsedReceipt.inAppPurchaseReceipts,
                    let currentSubscription = receipts.first(where: { (receipt) -> Bool in
                        if receipt.originalTransactionIdentifier == transactionID,
                        let expirationDate = receipt.subscriptionExpirationDate,
                            expirationDate > Date() {
                            return true
                        }
                        return false
                    }),
                    ArchiveService.shared.config.inAppProductItems.contains(currentSubscription.productIdentifier ?? "") else {
                        return
                }
                if let actualSubscription = self.currentSubscription,
                    actualSubscription.transactionToken == transactionID {
                    self.restoredSubscription = self.currentSubscription
                    DispatchQueue.main.async {
                        self.delegate?.subscriptionProcessEnd(.restorePurchases)
                    }
                    return
                }
                if self.currentProcess == .restorePurchases {
                    self.restoredTransactionID = transactionID
                }
                let data = PaymentData(transactionToken: transactionID, productName: productID)
                self.restUpdatePaymentPlan(data: data)
            }
        case .error(let error):
            delegate?.subscriptionProcessFailed(.subscribe, with: error)
        }
    }

    func iapCanceled() {
        delegate?.subscriptionProcessEndWithCancel(currentProcess)
    }

    func iapRestoreComplete() {
        if currentProcess == .restorePurchases, restoredTransactionID == nil, restoredSubscription == nil {
            delegate?.subscriptionProcessEnd(.restorePurchases)
        }
    }
}

// MARK: - REST requests

extension SubscriptionsManager {

    private func restGetCurrentPaymentPlan(completion: (() -> Void)? = nil) {
        restPaymentsManager.getCurrentPlan()
            .onStateChanged { (state) in
                if state == .ended {
                    self.delegate?.subscriptionProcessEnd(.getCurrentSubscription)
                    completion?()
                }
        }.onError { [weak self] (error) in
            self?.delegate?.subscriptionProcessFailed(.getCurrentSubscription, with: error)
        }.onComplete { [weak self] (response) in
            self?.currentSubscription = response.result
            self?.delegate?.currentSubscriptionReceived(response.result)
        }.run()
    }

    private func restUpdatePaymentPlan(data: PaymentData) {
        restPaymentsManager.updatePlan(data: data)
        .onError { [weak self] (error) in
            if self?.currentProcess == .restorePurchases {
                self?.delegate?.subscriptionProcessEnd(nil)
            } else {
                self?.delegate?.subscriptionProcessEnd(self?.currentProcess)
            }
            self?.delegate?.subscriptionProcessFailed(.subscribe, with: error)
        }.onComplete { [weak self] (response) in
            if self?.currentSubscription == nil {
                AnalyticsService.logFirstPayment()
            } else {
                AnalyticsService.logRecurringPayment()
            }
            self?.currentSubscription = response.result
            self?.delegate?.currentSubscriptionReceived(response.result)
            if self?.currentProcess == .restorePurchases {
                self?.restoredSubscription = response.result
            }
            self?.delegate?.subscriptionProcessEnd(self?.currentProcess)
        }.run()
    }

    private func restRemovePaymentPlan() {
        restPaymentsManager.cancelSubscription()
            .onStateChanged { (state) in
                if state == .ended {
                    self.delegate?.subscriptionProcessEnd(.unsubscribe)
                }
        }.onError { [weak self] (error) in
            self?.delegate?.subscriptionProcessFailed(.unsubscribe, with: error)
        }.onComplete { [weak self] (_) in
            self?.currentSubscription = nil
            self?.delegate?.currentSubscriptionReceived(nil)
        }.run()
    }
}
