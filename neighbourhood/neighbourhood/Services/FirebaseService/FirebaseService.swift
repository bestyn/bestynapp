//
//  FirebaseService.swift
//  neighbourhood
//
//  Created by Artem Korzh on 25.09.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import FirebaseDatabase

class FirebaseService {

    static let shared = FirebaseService()

    private let ref = Database.database().reference()
    var maintenanceRef: DatabaseReference { ref.child("maintenance") }
    var preAppRef: DatabaseReference { ref.child("preApp").child("iOS") }

    public func listenMaintenace(completion: @escaping (Bool) -> Void) {
        maintenanceRef.observe(.value) { (snapshot) in
            if let maintanence = snapshot.value as? Bool {
                completion(maintanence)
                return
            }
            completion(false)
        }
    }

    public func getPreAppVersion(completion: @escaping (String) -> Void) {
        preAppRef.observeSingleEvent(of: .value) { (snapshot) in
            if let value = snapshot.value as? String {
                completion(value)
                return
            }
            completion("")
        }
    }


    deinit {
        maintenanceRef.removeAllObservers()
    }


}
