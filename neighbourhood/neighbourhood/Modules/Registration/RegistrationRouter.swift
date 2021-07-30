//
//  RegistrationRouter.swift
//  neighbourhood
//
//  Created by Dioksa on 21.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import GBKRouterProtocol

struct RegistrationRouter: GBKRouterProtocol {
    var context: UINavigationController!
    
    func openSignUpScreen() {
        let controller = SignUpViewController()
        push(controller: controller)
    }
    
    func openCategoriesController(delegate: ChoseCategoryDelegate?) {
        let controller = CategoriesViewController()
        controller.delegate = delegate
        controller.modalPresentationStyle = .fullScreen
        push(controller: controller)
    }
}
