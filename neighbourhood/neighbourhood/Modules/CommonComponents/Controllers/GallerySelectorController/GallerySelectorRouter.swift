//
//  GallerySelectorRouter.swift
//  neighbourhood
//
//  Created by Artem Korzh on 23.12.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import GBKRouterProtocol

struct GallerySelectorRouter: GBKRouterProtocol {
    var context: UIViewController!

    func openGallerySelection(delegate: GallerySelectorDelegate) {
        let controller = GallerySelectorViewController()
        controller.modalPresentationStyle = .overCurrentContext
        controller.viewModel.delegate = delegate
        present(controller: controller)
    }
}
