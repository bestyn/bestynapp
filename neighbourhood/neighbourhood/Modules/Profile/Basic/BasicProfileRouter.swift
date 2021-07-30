//
//  BasicProfileRouter.swift
//  neighbourhood
//
//  Created by Dioksa on 13.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import GBKRouterProtocol

struct BasicProfileRouter: GBKRouterProtocol {
    var context: UINavigationController!
    
    private let postReports = ["Inappropriate content (offensive or abusive)", "Spam"]
    private let userReports = ["Fake Profile", "Privacy Violation", "Vandalism", "Inappropriate content (offensive or abusive)", "Spam"]
        
    func openPublicProfileViewController(profileId: Int) {
        let controller = PublicProfileViewController()
        controller.setupProfile(with: profileId)
        push(controller: controller)
    }
    
    func openProfileSettingsViewController() {
        let controller = ProfileSettingsViewController()
        push(controller: controller)
    }
    
    func openMyInterestsViewController(type: TypeOfScreenAction) {
        let controller = MyInterestsViewController(screenType: type)
        context.pushViewController(controller, animated: true)
    }

    func openCreatePost(of type: TypeOfPost, delegate: PostFormDelegate? = nil) {
        PostSaver.shared.createPost(type: type)
        let controller = PostFormViewController()
        controller.delegate = delegate
        push(controller: controller)
    }


    func openEditPost(post: PostModel, delegate: PostFormDelegate? = nil) {
        PostSaver.shared.edit(post: post)
        let controller = PostFormViewController()
        controller.delegate = delegate
        push(controller: controller)
    }
    
    func openReportViewController(for entity: Reportable) {
        let controller = ReportViewController(entity: entity)
        push(controller: controller)
    }

    func openAlbumList(profile: SelectorProfileModel, loadedPosts: [PostModel], selectedPostIndex: Int) {
        let controller = AlbumListViewController(profile: profile, loadedPosts: loadedPosts, selectedPostIndex: selectedPostIndex)
        push(controller: controller)
    }
}

