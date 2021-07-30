//
//  FollowRouter.swift
//  neighbourhood
//
//  Created by Artem Korzh on 09.03.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import Foundation
import GBKRouterProtocol

struct FollowRouter: GBKRouterProtocol {
    var context: UINavigationController!

    func openFollowers() {
        let controller = FollowListViewController(mode: .followers)
        push(controller: controller)
    }

    func openFollowed() {
        let controller = FollowListViewController(mode: .followed)
        push(controller: controller)
    }
}
