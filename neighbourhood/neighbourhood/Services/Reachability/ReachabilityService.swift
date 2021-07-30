//
//  ReachabilityService.swift
//  neighbourhood
//
//  Created by Dioksa on 15.07.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import Reachability
import UIKit

public enum ReachabilityError: Error {
    case notReachable
}

public enum ReachabilityStatus {
    case unknown
    case notReachable
    case reachable
}

public class ReachabilityService {
    
    // MARK: -
    // MARK: SINGLETON
    static let shared: ReachabilityService = ReachabilityService()

    private let reachability = try? Reachability()
    
    /// key to send notification by changing the status of the network
    public let reachabilityStatusChanged = NSNotification.Name(rawValue:"NSNotificationKeyReachabilityStatusChanged")

    init() {
        startListening()
        NotificationCenter.default.addObserver(self, selector: #selector(startListening), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stopListening), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    //MARK:-
    //MARK: check network
    
    /// checking internet connection
    ///
    /// - returns: network status
    public func isConnection() -> Bool {
        guard let reachability = reachability,
            reachability.connection == .unavailable else {
                return true
        }
        return false
    }
    
    /// checking internet connection (throws)
    ///
    /// - throws: in the absence of network
    public func checkingConnection() throws {
        if reachability?.connection == .unavailable {
            throw ReachabilityError.notReachable
        }
    }
    
    //MARK:-
    //MARK: listening
    
    /// start
    ///
    @objc public func startListening() {
        reachability?.whenReachable = { _ in
            NotificationCenter.default.post(
                name: self.reachabilityStatusChanged,
                object: nil,
                userInfo: ["status": ReachabilityStatus.reachable])
        }
        reachability?.whenUnreachable = { _ in
            NotificationCenter.default.post(
                name: self.reachabilityStatusChanged,
                object: nil,
                userInfo: ["status": ReachabilityStatus.notReachable])
        }

        try? reachability?.startNotifier()
    }
    
    /// stop
    ///
    @objc public func stopListening() {
        reachability?.stopNotifier()
    }
    
}
