//
//  MyPostsRouter.swift
//  neighbourhood
//
//  Created by Dioksa on 25.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import GBKRouterProtocol
import AVKit

struct MyPostsRouter: GBKRouterProtocol {
    var context: UINavigationController!
    
    func openImage(image: UIImage? = nil, imageUrl: URL? = nil) {
        let controller = FullScreenImageViewController()
        controller.imageToZoom(image: image)
        controller.imageUrl = imageUrl
        controller.modalPresentationStyle = .fullScreen
        present(controller: controller)
    }

    func openPostDetailsViewController(currentPost: PostModel, profileDelegate: PrivateProfileDelegate?, postDelegate: PostFormDelegate? = nil) {
        let controller = PostDetailsViewController(currentPost: currentPost)
        controller.profileDelegate = profileDelegate
        controller.postUpdateDelegate = postDelegate
        push(controller: controller)
    }

    func openPostDetailsViewController(postId: Int, profileDelegate: PrivateProfileDelegate?, postDelegate: PostFormDelegate? = nil) {
        let controller = PostDetailsViewController(postId: postId)
        controller.profileDelegate = profileDelegate
        controller.postUpdateDelegate = postDelegate
        push(controller: controller)
    }
    
    func createCategoriesController(delegate: ChoseCategoryDelegate?) -> CategoriesViewController {
        let controller = CategoriesViewController()
        controller.delegate = delegate
        controller.modalPresentationStyle = .fullScreen
        return controller
    }
    
    func openAvatarEdit(image: UIImage, initCrop: Rect? = nil, delegate: AvatarEditViewControllerDelegate) {
        let controller = AvatarEditViewController(image: image, initialCrop: initCrop)
        controller.delegate = delegate
        controller.modalPresentationStyle = .fullScreen
        present(controller: controller)
    }

    func openVideo(videoURL: URL) {
        let controller = FullScreenVideoViewController(videoURL: videoURL)
        controller.modalPresentationStyle = .fullScreen
        present(controller: controller)
    }

    func openHashtagPage(hashtag: String) {
        let controller = HashtagViewController(hashtag: hashtag)
        push(controller: controller)
    }

    func openRecordVoice(delegate: RecordVoiceDelegate) {
        let controller = RecordVoiceViewController()
        controller.viewModel.delegate = delegate
        push(controller: controller)
    }

    func returnToVoiceRecord() {
        guard RecordVoiceViewModel.shared.recordState == .recording ||
                RecordVoiceViewModel.shared.recordState == .recorded else {
            return
        }
        var controllers = context.viewControllers
        let postFormViewController = PostFormViewController()
        let recordViewController = RecordVoiceViewController()
        recordViewController.viewModel.delegate = postFormViewController.viewModel
        controllers.append(contentsOf: [postFormViewController, recordViewController])
        context.setViewControllers(controllers, animated: true)
    }

    func collapseVoiceRecording() {
        var controllers = context.viewControllers
        controllers.removeAll { (controller) -> Bool in
            return controller is PostFormViewController || controller is RecordVoiceViewController
        }
        context.setViewControllers(controllers, animated: true)
    }
}
