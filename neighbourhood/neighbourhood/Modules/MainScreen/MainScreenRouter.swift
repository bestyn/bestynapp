//
//  MainScreenRouter.swift
//  neighbourhood
//
//  Created by Dioksa on 24.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import GBKRouterProtocol

struct MainScreenRouter: GBKRouterProtocol {
    var context: UINavigationController!
    
    func createNeighbourhoodViewController() -> HomeViewController {
        return HomeViewController()
    }

    func createMyPostsViewController() -> MyPostsViewController {
        return MyPostsViewController()
    }
    
    func createChatListViewController() -> ChatsListViewController {
        return ChatsListViewController()
    }
    
    func createProfileViewController() -> ProfileViewController {
        return ProfileViewController()
    }

    func openMyProfile() {
        if let mainController = context.viewControllers.first(where: {$0 is MainViewController}) as? MainViewController {
            popTo(controller: mainController)
            mainController.openMyProfile()
        }
    }

    func openHomeFeed() {
        if let mainController = context.viewControllers.first(where: {$0 is MainViewController}) as? MainViewController {
            popTo(controller: mainController)
            mainController.openHomeFeed()
        }
    }
}
