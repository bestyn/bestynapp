//
//  SupportRouter.swift
//  neighbourhood
//
//  Created by Dioksa on 28.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import GBKRouterProtocol

struct SupportRouter: GBKRouterProtocol {

    var context: UINavigationController!

    func openPage(type: PageType) {
        let controller = PageViewController(type: type)
        push(controller: controller)
    }
}
