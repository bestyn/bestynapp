//
//  ArchiveService.swift
//  neighbourhood
//
//  Created by Dioksa on 22.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

class ArchiveService {

    static let shared = ArchiveService()
    private init() {}

    private let userDefaults = UserDefaults.standard

    func clear(_ key: String) {
        userDefaults.set(nil, forKey: key)
        userDefaults.synchronize()
    }

    func save<Model>(_ model: Model?, key: String) where Model: Codable {
        guard let model = model else {
            clear(key)
            return
        }
        do {
            let object = try PropertyListEncoder().encode(model)
            let data = try NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: true)
            userDefaults.set(data, forKey: key)
            userDefaults.synchronize()
        } catch let error {
            debugPrint(error)
        }
    }

    func getModel<Model>(type: Model.Type, key: String) -> Model? where Model: Codable {
        do {
            if let data = userDefaults.object(forKey: key) as? Data,
                let object = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? Data {
                return try PropertyListDecoder().decode(Model.self, from: object)
            }
        } catch let error {
            debugPrint(error)
        }
        return nil
    }
}

