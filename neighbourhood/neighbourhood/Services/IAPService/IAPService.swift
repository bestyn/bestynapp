//
//  IAPService.swift
//  neighbourhood
//
//  Created by Artem Korzh on 17.07.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import StoreKit

struct IAPProductModel {
    let id: String
    let priceString: String?
    let price: Double
    let name: String
}

struct PaymentReceipt {
    let data: Data
    let string: String
}

protocol IAPServiceDelegate: class {
    func iap(availableProducts: [IAPProductModel])
    func iap(didFailWithError error: Error)
    func iap(transationCompleteID transactionID: String, currentTransactionID: String, productID: String, receipt: PaymentReceipt)
    func iapCanceled()
    func iapRestoreComplete()
}

enum IAPError: Error {
    case noReceiptAvailable
}

class IAPService: NSObject {

    static let shared = IAPService()
    private override init() {}

    private var products: [String: SKProduct] = [:]
    private var request: SKProductsRequest?
    public weak var delegate: IAPServiceDelegate?
    public var canMakePayments: Bool {
        return SKPaymentQueue.canMakePayments()
    }

    func fetchProducts(productIDs: [String]) {
        let productIdentifiers = Set(productIDs)
        request = SKProductsRequest(productIdentifiers: productIdentifiers)
        request?.delegate = self
        request?.start()
    }

    func purchase(productID: String) {
        if let product = products[productID] {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)
        }
    }

    func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }

    public func getReceipt() -> PaymentReceipt? {
        let receiptUrl = Bundle.main.appStoreReceiptURL
        if let receiptUrl = receiptUrl, let receiptData = NSData(contentsOf: receiptUrl) {
            return PaymentReceipt(
                data: receiptData as Data,
                string: receiptData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            )
        }
        return nil
    }

    private func transactionComplete(originalTransactionID: String, transactionID: String, productID: String) {
        guard let receipt = getReceipt() else {
            delegate?.iap(didFailWithError: IAPError.noReceiptAvailable)
            return
        }
        delegate?.iap(transationCompleteID: originalTransactionID, currentTransactionID: transactionID, productID: productID, receipt: receipt)
    }
}

extension IAPService: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        response.invalidProductIdentifiers.forEach { productID in
            print("Invalid: \(productID)")
        }

        response.products.forEach { product in
            products[product.productIdentifier] = product
        }

        DispatchQueue.main.async {
            let delegateResponse = self.products.values.map({IAPProductModel(
                id: $0.productIdentifier,
                priceString: $0.regularPrice,
                price: $0.price.doubleValue,
                name: $0.localizedTitle)})
            self.delegate?.iap(availableProducts: delegateResponse)
        }
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.delegate?.iap(didFailWithError: error)
        }
    }
}


extension IAPService: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .failed:
                print("Transaction Failed \(transaction)")
                queue.finishTransaction(transaction)
                if let error = transaction.error {
                    if let skError = error as? SKError, skError.code == .paymentCancelled {
                        delegate?.iapCanceled()
                        return
                    }
                    delegate?.iap(didFailWithError: error)
                }
            case .purchased:
                print("Transaction purchased: \(transaction)")
                guard let originalTransactionID = transaction.original?.transactionIdentifier,
                    let transactionID = transaction.transactionIdentifier else {
                    return
                }
                let productID = transaction.payment.productIdentifier
                queue.finishTransaction(transaction)
                transactionComplete(originalTransactionID: originalTransactionID, transactionID: transactionID, productID: productID)
            case .restored:
                debugPrint("Transaction restored: \(transaction)")
                guard let productID = transaction.original?.payment.productIdentifier,
                    let originalTransactionID = transaction.original?.transactionIdentifier,
                    let transactionID = transaction.transactionIdentifier else {
                        return
                }
                queue.finishTransaction(transaction)
                transactionComplete(originalTransactionID: originalTransactionID, transactionID: transactionID, productID: productID)
            case .deferred, .purchasing:
                print("Transaction in progress: \(transaction)")
            @unknown default:
                print("Possible unpredicted state")
            }
        }
    }

    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        delegate?.iapRestoreComplete()
    }

    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        if let skError = error as? SKError, skError.code == .paymentCancelled {
            delegate?.iapCanceled()
            return
        }
        delegate?.iap(didFailWithError: error)
    }
}
