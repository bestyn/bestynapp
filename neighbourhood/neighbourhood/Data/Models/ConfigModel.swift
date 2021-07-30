//
//  ConfigModel.swift
//  neighbourhood
//
//  Created by Dioksa on 23.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

enum ErrorReplacement {
    case attribute(String)
    case comparable(String)
    case value(String)
    case min(String)
    case max(String)
    case requiredValue(String)

    func replace(in error: String) -> String {
        switch self {
        case .attribute(let attribute):
            return error.replacingOccurrences(of: "{attr}", with: attribute)
        case .comparable(let value):
            return error.replacingOccurrences(of: "{compareValueOrAttr}", with: value)
        case .value(let value):
            return error.replacingOccurrences(of: "{value}", with: value)
        case .min(let minValue):
            return error.replacingOccurrences(of: "{min}", with: minValue)
        case .max(let maxValue):
            return error.replacingOccurrences(of: "{max}", with: maxValue)
        case .requiredValue(let value):
            return error.replacingOccurrences(of: "{requiredValue}", with: value)
        }
    }
}

struct ConfigModel: Codable {
   // let parameters: ParametersModel
    let errors: [String: String]
    let inAppProductItems: [String]
    var isDefault: Bool = false

    static var `default`: ConfigModel {
        guard let fileURL = Bundle.main.url(forResource: "defaultConfig", withExtension: "json") else {
            fatalError("Cannot find default config file")
        }
        do {
            let json = try Data(contentsOf: fileURL)
            var config = try JSONDecoder().decode(ConfigModel.self, from: json)
            config.isDefault = true
            return config
        } catch let error {
            fatalError(error.localizedDescription)
        }
    }

    enum CodingKeys: String, CodingKey {
        case parameters, errors, inAppProductItems
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
       // parameters = try container.decode(.parameters)
        errors = try container.decode(.errors)
        inAppProductItems = try container.decode(.inAppProductItems)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        //try container.encode(parameters, forKey: .parameters)
        try container.encode(errors, forKey: .errors)
        try container.encode(inAppProductItems, forKey: .inAppProductItems)
    }


    func error(code: Int, replacements: [ErrorReplacement]) -> String? {
        let codeString = String(code)
        if let message = errors[codeString] {
            return formatedError(message, replacements: replacements)
        }
        if !isDefault {
            return ConfigModel.default.error(code: code, replacements: replacements)
        }
        return nil
    }

    private func formatedError(_ error: String, replacements: [ErrorReplacement]) -> String {
        var result = error
        for replacement in replacements {
            result = replacement.replace(in: result)
        }
        return result
    }
}
