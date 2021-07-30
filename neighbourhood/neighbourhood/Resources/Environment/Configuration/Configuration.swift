//
//  Configuration.swift
//  neighbourhood
//
//  Created by Dioksa on 22.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

enum Configuration {
    enum Error: Swift.Error {
        case missingKey, invalidValue
    }

    static func value<T>(for key: String) throws -> T where T: LosslessStringConvertible {
        guard let object = Bundle.main.object(forInfoDictionaryKey: key) else {
            throw Error.missingKey
        }

        switch object {
        case let value as T:
            return value
        case let string as String:
            guard let value = T(string) else { fallthrough }
            return value
        default:
            throw Error.invalidValue
        }
    }
}

// swiftlint:disable force_try
extension Configuration {
    enum Keys {
        static let baseURL = "API_BASE_URL"
        static let reviewBaseURL = "REVIEW_API_BASE_URL"
        static let centrifugoUrl = "CENTRIFUGO_URL"
        static let buildVersion = "CFBundleShortVersionString"
        static let appName = "CFBundleName"
    }

    static var baseURL: URL {
        return URL(string: try! Configuration.value(for: Keys.baseURL))!
    }

    static var reviewBaseURL: URL {
        return URL(string: try! Configuration.value(for: Keys.reviewBaseURL))!
    }

    static var centrifugoUrl: String {
        return try! Configuration.value(for: Keys.centrifugoUrl)
    }

    static var buildVersion: String {
        return try! Configuration.value(for: Keys.buildVersion)
    }

    static var appName: String {
        return try! Configuration.value(for: Keys.appName)
    }

    static var deviceID: String {
        if let id = UIDevice.current.identifierForVendor?.uuidString, !id.isEmpty {
            return id
        }
        if let customDeviceID = ArchiveService.shared.customDeviceID {
            return customDeviceID
        }
        let newDeviceID = UUID().uuidString
        ArchiveService.shared.customDeviceID = newDeviceID
        return newDeviceID
    }
}
