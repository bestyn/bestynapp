//
//  OnDemandRecourcesServices.swift
//  neighbourhood
//
//  Created by Artem Korzh on 09.09.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

typealias OnDemandResponse = (_ error: Error?) -> Void

class OnDemandRecourcesServices {
    static let shared = OnDemandRecourcesServices()

    private var request: NSBundleResourceRequest?

    func preloadResources(tag: String, completion: @escaping OnDemandResponse) {
        request = NSBundleResourceRequest(tags: [tag])
        request?.conditionallyBeginAccessingResources(completionHandler: { [weak self] (resourceAvailable) in
            if resourceAvailable {
                completion(nil)
                return
            }
            self?.request?.endAccessingResources()
            self?.request?.loadingPriority = NSBundleResourceRequestLoadingPriorityUrgent
            self?.request?.beginAccessingResources(completionHandler: { (error) in
                if let error = error {
                    completion(error)
                    return
                }
                completion(nil)
            })
        })
    }
}
