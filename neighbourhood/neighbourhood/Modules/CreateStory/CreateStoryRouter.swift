//
//  CreateStoryRouter.swift
//  neighbourhood
//
//  Created by Artem Korzh on 26.11.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import GBKRouterProtocol
import AVFoundation

struct CreateStoryRouter: GBKRouterProtocol {
    var context: UINavigationController!

    func openCreateStory() {
        let controller = CreateStoryViewController()
        push(controller: controller)
    }

    func openPreview() {
        let controller = PreviewStoryViewController()
        push(controller: controller)
    }

    func backToPreview() {
        if let controller = context.viewControllers.first(where: {$0 is PreviewStoryViewController}) {
            popTo(controller: controller)
        } else {
            popController()
            let controller = PreviewStoryViewController()
            push(controller: controller)
        }
    }

    func openDescription() {
        let controller = StoryDescriptionViewController()
        push(controller: controller)
    }

    func backToList() {
        if let controller = context.viewControllers.first(where: {$0 is MainViewController}) {
            context.popToViewController(controller, animated: true)
        }
    }

    func openEditStory(storyPost: PostModel) {
        let controller = StoryDescriptionViewController(postToEdit: storyPost)
        push(controller: controller)
    }

    func openThumbnailSelector(from assetParams: VideoAssetParams, selectedSecond: Int, delegate: ThumbnailSelectionViewControllerDelegate) {
        let controller = ThumbnailSelectionViewController(assetParams: assetParams, selectedSecond: selectedSecond)
        controller.modalPresentationStyle = .overCurrentContext
        controller.delegate = delegate
        present(controller: controller)
    }

    func openClipAdjustment(delegate: ClipAdjustmentViewControllerDelegate?) {
        let controller = ClipAdjustmentViewController()
        controller.delegate = delegate
        push(controller: controller)
    }

    func openGalleryClipAdjustment() {
        var controllers = context.viewControllers
        let previewController = PreviewStoryViewController()
        controllers.append(previewController)
        let controller = ClipAdjustmentViewController()
        controller.delegate = previewController.viewModel
        controllers.append(controller)
        context.setViewControllers(controllers, animated: true)
    }

    func openTextEditor(entityToEdit: TextEditorEntity? = nil, delegate: StoryTextEditorViewControllerDelegate? = nil, animated: Bool = true) {
        let controller = StoryTextEditorViewController(textEntity: entityToEdit)
        controller.delegate = delegate
        controller.modalPresentationStyle = .overCurrentContext
        present(controller: controller, animated: animated)
    }

    func openTextStoryCreation() {
        StoryCreator.shared.setMode(.text)
        let previewController = PreviewStoryViewController()
        push(controller: previewController)
    }

    func openEffectDuration(for textEntity: StoryCreator.TextEntity, delegate: EffectDurationDelegate? = nil) {
        let controller = EffectDurationViewController(textEntity: textEntity)
        controller.viewModel.delegate = delegate
        push(controller: controller)
    }

    func returnToCreateStory() {
        if let controller = context.viewControllers.first(where: {$0 is CreateStoryViewController}) {
            popTo(controller: controller)
        }
    }

    func openAudioTracks(delegate: AudioListViewControllerDelegate) {
        let controller = AudioListViewController()
        controller.delegate = delegate
        push(controller: controller)
    }

    func returnToMyTracks() {
        if let controller = context.viewControllers.first(where: {$0 is AudioListViewController}) as? AudioListViewController {
            context.popToViewController(controller, animated: true)
            controller.changeFilter(filter: .myTracks)
        }
    }

    func openAudioTrim(track: StoryCreator.AudioTrack, delegate: AudioTrackEditViewControllerDelegate, onDismiss: @escaping () -> Void) {
        let controller = AudioTrackEditViewController(track: track)
        controller.delegate = delegate
        BottomMenuPresentationManager.present(
            controller,
            from: context,
            configureBackView: { (view) in
                view.layer.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.2).cgColor
                view.layer.borderWidth = 1
                view.layer.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5).cgColor

                if !UIAccessibility.isReduceTransparencyEnabled {
                    let blurEffect = UIBlurEffect(style: .light)
                    let blurEffectView = UIVisualEffectView(effect: blurEffect)

                    blurEffectView.frame = view.bounds
                    blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

                    blurEffectView.translatesAutoresizingMaskIntoConstraints = false
                    blurEffectView.alpha = 0.9
                    view.insertSubview(blurEffectView, at: 0)
                }

                let closeButton = UIButton()
                closeButton.setImage(R.image.stories_close_icon(), for: .normal)
                closeButton.addTarget(controller, action: #selector(controller.close), for: .touchUpInside)
                view.addSubview(closeButton)
                closeButton.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 15),
                    closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
                    closeButton.widthAnchor.constraint(equalToConstant: 25),
                    closeButton.heightAnchor.constraint(equalToConstant: 25)
                ])
            },
            configureIndicatorView: { (indicator) in
                indicator.backgroundColor = .white
            },
            onDismiss: onDismiss)
    }

    func openAudioVolume(delegate: VolumeAdjustmentViewControllerDelegate) {
        let controller = VolumeAdjustmentViewController()
        controller.delegete = delegate
        BottomMenuPresentationManager.present(
            controller,
            from: context,
            configureBackView: { (view) in
                view.layer.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.2).cgColor
                view.layer.borderWidth = 1
                view.layer.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5).cgColor

                if !UIAccessibility.isReduceTransparencyEnabled {
                    let blurEffect = UIBlurEffect(style: .light)
                    let blurEffectView = UIVisualEffectView(effect: blurEffect)

                    blurEffectView.frame = view.bounds
                    blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

                    blurEffectView.translatesAutoresizingMaskIntoConstraints = false
                    blurEffectView.alpha = 0.9
                    view.insertSubview(blurEffectView, at: 0)
                }

                let closeButton = UIButton()
                closeButton.setImage(R.image.stories_close_icon(), for: .normal)
                closeButton.addTarget(controller, action: #selector(controller.close), for: .touchUpInside)
                view.addSubview(closeButton)
                closeButton.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 15),
                    closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
                    closeButton.widthAnchor.constraint(equalToConstant: 25),
                    closeButton.heightAnchor.constraint(equalToConstant: 25)
                ])
            },
            configureIndicatorView: { (indicator) in
                indicator.backgroundColor = .white
            })
    }

    public func openAddTrack(for url: URL) {
        let controller = AddAudioTrackViewController(audioTrackURL: url)
        push(controller: controller)
    }

    public func openCreateDuet(with story: PostModel) {
        let controller = CreateDuetViewController(originStory: story)
        push(controller: controller)
    }
}
