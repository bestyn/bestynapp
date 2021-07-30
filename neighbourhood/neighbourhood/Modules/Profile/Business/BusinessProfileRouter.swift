//
//  BusinessProfileRouter.swift
//  neighbourhood
//
//  Created by Dioksa on 13.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import GBKRouterProtocol

struct BusinessProfileRouter: GBKRouterProtocol {
    var context: UINavigationController!
    
    func openAddBusinessProfile() {
        let controller = AddBusinessProfileViewController()
        controller.screenType = .create
        push(controller: controller)
    }

    func openEditBusinessProfile(profile: BusinessProfile) {
        let controller = AddBusinessProfileViewController()
        controller.screenType = .edit
        controller.businessProfile = profile
        push(controller: controller)
    }
    
    func openMyBusinessViewController() {
        let controller = MyBusinessViewController()
        push(controller: controller)
    }

    func openPaymentPlansViewController() {
        let controller = PlansViewController()
        push(controller: controller)
    }
    
    func createBusinessViewController(business: BusinessProfile?) -> MyBusinessViewController {
        let controller = MyBusinessViewController()
        controller.setupBusinessProfile(business)
        return controller
    }
    
    func openPublicProfileController(id: Int) {
        let controller = PublicBusinessViewController()
        controller.setupProfile(with: id)
        push(controller: controller)
    }
}
