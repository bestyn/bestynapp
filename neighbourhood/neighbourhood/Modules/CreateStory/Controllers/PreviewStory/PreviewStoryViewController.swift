//
//  PreviewStoryViewController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 01.12.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import AVFoundation

class PreviewStoryViewController: UIViewController {

    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var muteButton: UIButton!
    @IBOutlet weak var adjustButton: UIButton!
    @IBOutlet weak var textButton: UIButton!
    @IBOutlet weak var contentContainer: UIView!
    @IBOutlet weak var contextMenu: UIView!
    @IBOutlet weak var contextMenuPointer: UIImageView!
    @IBOutlet weak var contextMenuStackView: UIStackView!
    @IBOutlet weak var galleryButton: DoubleBorderedButton!
    @IBOutlet weak var gradientPickerView: UIView!
    @IBOutlet weak var textBackgroundButton: UIButton!
    @IBOutlet weak var gradientCollectionView: UICollectionView!
    @IBOutlet var durationButtons: [UIButton]!
    @IBOutlet weak var durationButtonsStackView: UIStackView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var volumeButton: UIButton!

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet var uiViews: [UIView]!

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    let viewModel = PreviewStoryViewModel()
    private var looper: AVPlayerLooper!
    private var player = AVQueuePlayer()
    private var timeObserver: Any?
    private lazy var playerLayer = AVPlayerLayer(player: player)
    private var textViews: [UIView: StoryCreator.TextEntity] = [:]
    private var tappedText: StoryCreator.TextEntity?
    private let gradients = StoryGradient.available

    private var isGradientShown = false {
        didSet { toggleGradientViews() }
    }

    private var editController: AudioTrackEditViewController? {
        children.first(where: {$0 is AudioTrackEditViewController}) as? AudioTrackEditViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupPlayerView()
        setupViewModel()
        setupGestureRecognizers()
        setupGalleryButton()
        setupGradientPicker()
        if viewModel.isTextStoryMode {
            toggleUI(isHidden: true)
            CreateStoryRouter(in: navigationController).openTextEditor(delegate: self, animated: false)
            setupBackgroundLayer()
            setupDurationButtons()
            muteButton.isHidden = true
        }
        adjustButton.isHidden = !viewModel.isAdjustClipAvailable


        NotificationCenter.default.addObserver(self, selector: #selector(testImage(notification:)), name: NSNotification.Name(rawValue: "TESTIMAGE"), object: nil)
    }

    @objc private func testImage(notification: Notification) {
        if let image = notification.object as? UIImage {
            imageView.image = image
        }
    }

    deinit {
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        NotificationCenter.default.removeObserver(self)
        debugPrint("deinit \(name)")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        player.play()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer.frame = videoView.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player.pause()
    }


    @IBAction func didTapBackButton(_ sender: Any) {
        askForCancel()
    }

    @IBAction func didTapMute(_ sender: Any) {
        viewModel.toggleMute()
    }

    @IBAction func didTapNext(_ sender: Any) {
        CreateStoryRouter(in: navigationController).openDescription()
    }

    @IBAction func didTapAdjustment(_ sender: Any) {
        openAdjustClips()
    }

    @IBAction func didTapGallery(_ sender: Any) {
        askForGallery()
    }
    
    @IBAction func didTapAddText(_ sender: Any) {
        if viewModel.texts.count == 10 {
            Toast.show(message: Alert.Message.cantAddText)
            return
        }
        toggleUI(isHidden: true)
        CreateStoryRouter(in: navigationController).openTextEditor(delegate: self)
    }

    @IBAction func didTapEdit(_ sender: Any) {
        hideContextMenu()
        openEditText()
    }

    @IBAction func didTapSetDuration(_ sender: Any) {
        hideContextMenu()
        if let tappedText = tappedText {
            CreateStoryRouter(in: navigationController).openEffectDuration(for: tappedText, delegate: viewModel)
        }
    }

    @IBAction func didTapDelete(_ sender: Any) {
        hideContextMenu()
        guard tappedText != nil else {
            return
        }
        askForDeleteText()
    }

    @IBAction func didTapChangeBackground(_ sender: Any) {
        isGradientShown = true
    }

    @IBAction func didTapAddSound(_ sender: Any) {
        if let track = viewModel.storyCreator.backgroundSong {
            openTrimTrack(track: track)
        } else {
            CreateStoryRouter(in: navigationController).openAudioTracks(delegate: self)
        }
    }

    @IBAction func didTapAdjustVolume(_ sender: Any) {
        CreateStoryRouter(in: navigationController).openAudioVolume(delegate: viewModel)
    }
}

// MARK: - Configuration

extension PreviewStoryViewController {

    private func setupPlayerView() {
        playerLayer.frame = videoView.bounds
        playerLayer.videoGravity = .resizeAspectFill
        videoView.layer.addSublayer(playerLayer)
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.01, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: .main, using: { [weak self] (time) in
            self?.textViews.forEach { (view, text) in
                guard let range = text.range else {
                    return
                }
                view.isHidden = !range.contains(time.seconds)
            }
            self?.editController?.currentSecond = time.seconds
        })
    }

    private func setupGestureRecognizers() {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleAllOverTap(recognizer:)))
        tapRecognizer.cancelsTouchesInView = false
        view.addGestureRecognizer(tapRecognizer)
    }

    private func setupViewModel() {
        viewModel.$assetParams.bind { [weak self] (assetParams) in
            guard let self = self, let assetParams = assetParams else {
                return
            }
            self.player.pause()
            let item = AVPlayerItem(asset: assetParams.asset)
            item.videoComposition = assetParams.videoComposition
            item.audioMix = assetParams.audioMix
            self.player.replaceCurrentItem(with: item)
            self.looper = .init(player: self.player, templateItem: item)
            self.player.play()
            self.volumeButton.isHidden = self.viewModel.storyCreator.backgroundSong == nil
        }

        viewModel.$isMuted.bind { [weak self] (isMuted) in
            self?.muteButton.setImage(isMuted ? R.image.stories_mute_icon() : R.image.stories_unmute_icon(), for: .normal)
            self?.player.isMuted = isMuted
        }

        viewModel.$texts.bind { [weak self] (texts) in
            guard let self = self else {
                return
            }
            self.contentContainer.subviews.forEach({$0.removeFromSuperview()})
            self.textViews = [:]
            for text in texts {
                let textView = HighlightTextView(textEditorEntity: text.editorEntity)
                textView.contentOffset = .zero
                textView.setSizeInScreen()
                textView.center = self.contentContainer.center
                let imageView = UIImageView(image: textView.screenshot)
                imageView.center = self.contentContainer.center
                imageView.transform = text.transform
                imageView.isUserInteractionEnabled = true
                self.contentContainer.addSubview(imageView)
                self.addContentRecognizers(view: imageView)
                self.textViews[imageView] = text
            }
        }
        
        viewModel.$gallerySelected.bind { [self] (_) in
            self.openAdjustClips()
        }

        viewModel.$audioMix.bind { [weak self] (audioMix) in
            if let audioMix = audioMix {
                self?.player.currentItem?.audioMix = audioMix
            }
        }
    }

    private func addContentRecognizers(view: UIView) {
        let moveRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleMove(recognizer:)))
        moveRecognizer.delegate = self
        let scaleRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handleScale(recognizer:)))
        scaleRecognizer.delegate = self
        let rotationRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(recognizer:)))
        rotationRecognizer.delegate = self
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        let longTapRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(recognizer:)))
        view.addGestureRecognizer(moveRecognizer)
        view.addGestureRecognizer(scaleRecognizer)
        view.addGestureRecognizer(rotationRecognizer)
        view.addGestureRecognizer(tapRecognizer)
        view.addGestureRecognizer(longTapRecognizer)
    }

    private func setupGalleryButton() {
        guard viewModel.isGalleryAvailable else {
            return
        }
        galleryButton.isHidden = false
        PermissionsService(shouldAskPermissions: false).checkPermission(types: [.gallery]) { (result) in
            if result.allGranted {
                let galleryService = GalleryService()
                if let asset = galleryService.fetchAssets(type: .all).firstObject {
                    galleryService.image(asset: asset, size: .init(width: 40, height: 40)) { (image) in
                        if let image = image {
                            self.galleryButton.setImage(image, for: .normal)
                        }
                    }
                }

            }
        }
    }

    private func setupGradientPicker() {
        textBackgroundButton.isHidden = !viewModel.isTextStoryMode
        gradientCollectionView.register(R.nib.gradientCell)
        gradientCollectionView.allowsMultipleSelection = false
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = gradientPickerView.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        gradientPickerView.insertSubview(blurEffectView, at: 0)
        gradientPickerView.roundCorners(corners: [.topLeft, .topRight], radius: 16)
        gradientCollectionView.selectItem(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .centeredHorizontally)
    }

    private func setupBackgroundLayer() {
        viewModel.textBackgroundLayer.removeFromSuperlayer()
        viewModel.textBackgroundLayer.frame = contentContainer.bounds.insetBy(dx: contentContainer.bounds.width / -2, dy: contentContainer.bounds.height / -2)
        contentContainer.layer.addSublayer(viewModel.textBackgroundLayer)
    }

    private func setupDurationButtons() {
        durationButtonsStackView.isHidden = false
        durationButtons.forEach { (button) in
            button.setBackgroundColor(color: UIColor.white.withAlphaComponent(0.2), forState: .normal)
            button.setBackgroundColor(color: UIColor.white.withAlphaComponent(0.6), forState: .disabled)
            button.addTarget(self, action: #selector(didTapDuration(button:)), for: .touchUpInside)
        }
        durationButtons.last?.isEnabled = false
    }
}

// MARK: - Private methods

extension PreviewStoryViewController {
    private func askForCancel() {
        Alert(title: nil, message: Alert.Message.cancelChanges)
            .configure(doneText: Alert.Action.ok)
            .configure(cancelText: Alert.Action.cancel)
            .show { (result) in
                if result == .done {
                    self.viewModel.cancelCreation()
                    self.navigationController?.popViewController(animated: true)
                }
            }
    }

    private func askForDeleteText() {
        Alert(title: nil, message: Alert.Message.deleteStoryText)
            .configure(doneText: Alert.Action.delete)
            .configure(cancelText: Alert.Action.cancel)
            .show { [weak self] (result) in
                if result == .done {
                    if let tappedText = self?.tappedText {
                        self?.viewModel.removeText(entity: tappedText)
                    }
                }
            }
    }
    private func openAdjustClips() {
        func openAdjust() {
            self.player.pause()
            CreateStoryRouter(in: self.navigationController).openClipAdjustment(delegate: self.viewModel)
        }

        if textViews.count > 0 {
            Alert(title: nil, message: Alert.Message.adjustConfirm)
                .configure(doneText: Alert.Action.yes)
                .configure(cancelText: Alert.Action.cancel)
                .show { (result) in
                    if result == .done {
                        openAdjust()
                    }
                }
        } else {
            openAdjust()
        }

    }

    private func askForGallery() {
        Alert(title: Alert.Title.createNewStory, message: Alert.Message.recreateFromGallery)
            .configure(doneText: Alert.Action.yes)
            .configure(cancelText: Alert.Action.cancel)
            .show { [weak self] (result) in
                if result == .done {
                    self?.openGallery()
                }
            }
    }

    private func toggleUI(isHidden: Bool) {
        uiViews.forEach({$0.isHidden = isHidden})
    }

    @objc private func handleScale(recognizer: UIPinchGestureRecognizer) {
        guard let view = recognizer.view else { return }
        switch recognizer.state {
        case .began:
            touchStarted(for: view)
            fallthrough
        case .changed:
            let scale = recognizer.scale
            view.transform = view.transform.scaledBy(x: scale, y: scale)
            recognizer.scale = 1
        case .ended:
            touchEnded(for: view)
        default:
            break
        }
    }

    @objc private func handleMove(recognizer: UIPanGestureRecognizer) {
        guard let view = recognizer.view else { return }
        switch recognizer.state {
        case .began:
            touchStarted(for: view)
            fallthrough
        case .changed:
            let translation = recognizer.translation(in: view)
            view.transform = view.transform.translatedBy(x: translation.x, y: translation.y)
            recognizer.setTranslation(.zero, in: view)
        case .ended:
            touchEnded(for: view)
        default:
            break
        }
    }

    @objc private func handleRotation(recognizer: UIRotationGestureRecognizer) {
        guard let view = recognizer.view else { return }
        switch recognizer.state {
        case .began:
            touchStarted(for: view)
            fallthrough
        case .changed:
            view.transform = view.transform.rotated(by: recognizer.rotation)
            recognizer.rotation = 0
        case .ended:
            touchEnded(for: view)
        default:
            break
        }
    }

    @objc private func handleTap(recognizer: UITapGestureRecognizer) {
        isGradientShown = false
        guard let view = recognizer.view else { return }
        if let text = textViews[view] {
            tappedText = text
            openEditText()
        }
    }

    @objc private func handleLongPress(recognizer: UILongPressGestureRecognizer) {
        guard let view = recognizer.view else { return }
        if let text = textViews[view] {
            tappedText = text
            showContextMenu(for: view, tapLocation: recognizer.location(in: self.view))
        }
    }

    @objc private func handleAllOverTap(recognizer: UIRotationGestureRecognizer) {
        let location = recognizer.location(in: view)
        if !contextMenu.frame.contains(location) {
            hideContextMenu()
        }
        if !gradientPickerView.frame.contains(location) {
            isGradientShown = false
        }
    }


    private func touchStarted(for view: UIView) {
        view.superview?.bringSubviewToFront(view)
        toggleUI(isHidden: true)
        hideContextMenu()
        player.pause()
    }

    private func touchEnded(for view: UIView) {
        toggleUI(isHidden: false)
        player.play()
        if let text = textViews[view] {
            viewModel.updateTextTransform(entity: text, transform: view.transform)
        }
    }

    private func openEditText() {
        guard let text = tappedText else {
            return
        }
        viewModel.editText(entity: text)
        toggleUI(isHidden: true)
        CreateStoryRouter(in: navigationController).openTextEditor(entityToEdit: text.editorEntity, delegate: self)
    }

    private func showContextMenu(for view: UIView, tapLocation: CGPoint) {
        let bottomCenterPoint = CGPoint(x: view.frame.minX + view.frame.width / 2, y: view.frame.maxY)
        let topCenterPoint = CGPoint(x: view.frame.minX + view.frame.width / 2, y: view.frame.minY)
        let destinationPoint: CGPoint
        var rotated = false
        if bottomCenterPoint.y + contextMenu.bounds.height < self.view.bounds.height {
            destinationPoint = bottomCenterPoint
        } else if topCenterPoint.y - contextMenu.bounds.height > 0 {
            destinationPoint = topCenterPoint
            rotated = true
        } else  {
            destinationPoint = tapLocation
            if tapLocation.y + contextMenu.bounds.height > self.view.bounds.height {
                rotated = true
            }
        }
        let menuCenter = CGPoint(
            x: min(self.view.bounds.width - 10 - contextMenu.bounds.width / 2, max(destinationPoint.x, 10 + contextMenu.bounds.width / 2)),
            y: destinationPoint.y + contextMenu.bounds.height / 2 * (rotated ? -1 : 1) )

        contextMenuStackView.removeArrangedSubview(contextMenuPointer)
        if rotated {
            contextMenuStackView.insertArrangedSubview(contextMenuPointer, at: 1)
            contextMenuPointer.transform = CGAffineTransform(rotationAngle: .pi)
        } else {
            contextMenuStackView.insertArrangedSubview(contextMenuPointer, at: 0)
            contextMenuPointer.transform = .identity
        }
        contextMenuStackView.setNeedsLayout()
        print(menuCenter)

        contextMenu.transform = CGAffineTransform(
            translationX: menuCenter.x - contextMenu.center.x,
            y: menuCenter.y - contextMenu.center.y)
        contextMenu.isHidden = false
    }

    private func hideContextMenu() {
        contextMenu.isHidden = true
    }
    
    private func openGallery() {
        PermissionsService().checkPermission(types: [.gallery]) { [weak self] (result) in
            guard result.allGranted else {
                Alert(title: Alert.Title.galleryPermissions, message: Alert.Message.galleryPermissions(appName: Configuration.appName))
                    .configure(doneText: Alert.Action.openSettings)
                    .configure(cancelText: Alert.Action.cancel)
                    .show { (result) in
                        if result == .done,
                           let url = URL(string: UIApplication.openSettingsURLString),
                           UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }
                return
            }
            if let self = self {
                GallerySelectorRouter(in: self.navigationController).openGallerySelection(delegate: self.viewModel)
            }
        }
    }

    @objc func didTapDuration(button: UIButton) {
        guard let index = durationButtons.firstIndex(of: button) else {
            return
        }
        durationButtons.forEach({$0.isEnabled = true})
        button.isEnabled = false
        viewModel.setTextStoryDuration(viewModel.textDurations[index])
    }

    private func toggleGradientViews() {
        gradientPickerView.isHidden = !isGradientShown
        nextButton.isHidden = isGradientShown
        durationButtonsStackView.isHidden = !viewModel.isTextStoryMode || isGradientShown
        textBackgroundButton.borderWidth = isGradientShown ? 1 : 0
    }

    private func openTrimTrack(track: StoryCreator.AudioTrack) {
        viewModel.beginEdit()
        let editController = AudioTrackEditViewController(track: track)
        editController.delegate = self
        let pullableView = BottomPullableView(nestedView: editController.view)
        view.addSubview(pullableView)
        addChild(editController)
        editController.didMove(toParent: self)
        pullableView.onPullDown = { [weak self] in
            self?.didTapCloseEdit()
        }
        pullableView.configureBackView = { backView in
            backView.layer.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.2).cgColor
            backView.layer.borderWidth = 1
            backView.layer.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5).cgColor

            if !UIAccessibility.isReduceTransparencyEnabled {
                let blurEffect = UIBlurEffect(style: .extraLight)
                let blurEffectView = UIVisualEffectView(effect: blurEffect)

                blurEffectView.frame = backView.bounds
                blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

                blurEffectView.translatesAutoresizingMaskIntoConstraints = false
                blurEffectView.alpha = 0.9
                backView.insertSubview(blurEffectView, at: 0)
            }
        }

        pullableView.configureIndicatorView = { indicator in
            indicator.backgroundColor = .white
        }

        let closeButton = UIButton()
        closeButton.setImage(R.image.stories_close_icon(), for: .normal)
        closeButton.addTarget(self, action: #selector(didTapCloseEdit), for: .touchUpInside)
        pullableView.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: pullableView.topAnchor, constant: 15),
            closeButton.trailingAnchor.constraint(equalTo: pullableView.trailingAnchor, constant: -15),
            closeButton.widthAnchor.constraint(equalToConstant: 25),
            closeButton.heightAnchor.constraint(equalToConstant: 25)
        ])

        view.addSubview(pullableView)
        let top = UIScreen.main.bounds.height - editController.presentedViewHeight
        pullableView.frame = CGRect(origin: CGPoint(x: 0, y: top), size: CGSize(width: UIScreen.main.bounds.width, height: editController.presentedViewHeight))
        pullableView.transform = CGAffineTransform(translationX: 0, y: pullableView.frame.height)
        UIView.animate(withDuration: 0.3) {
            pullableView.transform = .identity
        }
    }

    @objc private func  didTapCloseEdit() {
        guard let editController = editController,
              let editView = view.subviews.first(where: {$0.subviews.contains(editController.view)}) else {
            return
        }
        editView.layer.removeAllAnimations()
        Alert(title: nil, message: Alert.Message.cancelChanges)
            .configure(doneText: Alert.Action.ok)
            .configure(cancelText: Alert.Action.cancel)
            .show { [weak self] (result) in
                if result == .done {
                    self?.viewModel.cancelEdit()
                    self?.closeEdit()
                } else {
                    UIView.animate(withDuration: 0.3) {
                        editView.transform = CGAffineTransform(translationX: 0, y: (UIScreen.main.bounds.height - editView.frame.height) - editView.frame.minY)
                    }
                }
            }
    }

    private func closeEdit() {
        guard let editController = editController,
              let editView = self.view.subviews.first(where: {$0.subviews.contains(editController.view)}) else {
            return
        }

        UIView.animate(withDuration: 0.3) {
            editView.transform = CGAffineTransform(translationX: 0, y: editView.frame.height)
        } completion: { _ in
            editController.removeFromParent()
            editView.removeFromSuperview()
        }
    }
}

// MARK: - StoryTextEditorViewControllerDelegate

extension PreviewStoryViewController: StoryTextEditorViewControllerDelegate {
    func textEditingComplete(entity: TextEditorEntity) {
        toggleUI(isHidden: false)
        viewModel.addText(entity: entity)
    }

    func textEditingCanceled() {
        toggleUI(isHidden: false)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension PreviewStoryViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate

extension PreviewStoryViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gradients.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.reuseIdentifier.gradientCell, for: indexPath)!
        cell.gradient = gradients[indexPath.row]
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let gradient = gradients[indexPath.row]
        viewModel.changeGradient(gradient)
    }
}

// MARK: - AudioTrackEditViewControllerDelegate

extension PreviewStoryViewController: AudioTrackEditViewControllerDelegate {
    func startPositionChanged(seconds: Double) {
        viewModel.setTrackTime(start: seconds)
    }

    func changeTrack() {
        viewModel.cancelEdit()
        closeEdit()
        CreateStoryRouter(in: navigationController).openAudioTracks(delegate: self)
    }

    func confirmChanges() {
        viewModel.confirmEdit()
        closeEdit()
    }
}

// MARK: - AudioListViewControllerDelegate

extension PreviewStoryViewController: AudioListViewControllerDelegate {
    func trackSelected(_ track: AudioTrackModel) {
        viewModel.selectTrack(track: track)
        player.pause()
        if let track = viewModel.storyCreator.backgroundSong {
            openTrimTrack(track: track)
        }
    }
}
