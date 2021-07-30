//
//  ChatDetailsViewController.swift
//  neighbourhood
//
//  Created by Dioksa on 25.06.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import Kingfisher
import AVKit
import MobileCoreServices
import AVFoundation
import SoundWave

private class DateHeaderLabel: UILabel {
    override var intrinsicContentSize: CGSize {
        let originalContentSize = super.intrinsicContentSize
        let height = originalContentSize.height + 12.0
        layer.cornerRadius = height / 2
        layer.masksToBounds = true
        return CGSize(width: originalContentSize.width + 20.0, height: height)
    }
}

final class ChatDetailsViewController: BaseViewController, AVAudioRecorderDelegate {
    @IBOutlet private weak var profileNameLabel: UILabel!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var chatView: ChatTextFieldView!
    @IBOutlet private weak var goToProfileButton: UIButton!
    @IBOutlet weak var avatarView: SmallAvatarView!
    @IBOutlet weak var typingStateLabel: UILabel!
    @IBOutlet weak var activityStateView: UIStackView!
    @IBOutlet weak var activityStateIndicator: UIView!
    @IBOutlet weak var activityStateLabel: UILabel!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var mentionsView: MentionsView!
    

    private lazy var mediaProcessor: MediaProcessor = MediaProcessor(viewController: self, delegate: self)

    private var tapRecognizer = UITapGestureRecognizer(target: self, action: nil)
    private let validation = ValidationManager()

    private var recordingSession: AVAudioSession!
    private var audioRecorder: AVAudioRecorder!
    private var audioFileName: URL?
    
    private let voiceManager = VoiceMessageManager()
    private var tappedCell: UITableViewCell?

    private var audioData: [URL: Data] = [:]
    private var editedIndexPath: IndexPath?

    private(set) var viewModel: ChatDetailsViewModel!

    init(opponent: ChatProfile) {
        self.viewModel = .init(opponent: opponent)
        super.init(nibName: nil, bundle: nil)
    }

    init(chat: PrivateChatListModel) {
        self.viewModel = .init(chat: chat)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        VoiceMessageManager.shared.stopPlaying()
        VoiceMessageManager.shared.stopSpeaking()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        configureChatView()
        configureLongTap()
        setupViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setChatBackground()
    }

    private func setupViewModel() {
        viewModel.$opponent.bind { [weak self] (profile) in
            guard let profile = profile else {
                return
            }
            self?.updateProfileInfo(profile: profile)
        }
        viewModel.$isLoading.bind { [weak self] (isLoading) in
            guard let self = self else {
                return
            }
            if isLoading {
                if self.viewModel.messageGroups.count == 0 {
                    self.loadingIndicator.isHidden = false
                }
            } else {
                self.loadingIndicator.isHidden = true
            }
        }

        viewModel.$isSending.bind { [weak self] (isSending) in
            self?.chatView.recordButton.isLoading = isSending
        }
        viewModel.$messageGroups.bind { [weak self] (messageGroups) in
            self?.tableView.reloadData()
            var messageIndex: Int?
            if let groupIndex = messageGroups.lastIndex(where: { group -> Bool in
                let unreadMessageIndex = group.messages.lastIndex(where: { message -> Bool in
                    return message is UnreadMark
                })
                messageIndex = unreadMessageIndex
                return unreadMessageIndex != nil
            }), let messageIndex = messageIndex {
                self?.tableView.scrollToRow(at: IndexPath(row: messageIndex, section: groupIndex), at: .bottom, animated: true)
            }
        }

        viewModel.$lastError.bind { [weak self] (error) in
            if let error = error {
                self?.handleError(error)
            }
        }
        
    }

    private func updateProfileInfo(profile: ChatProfile) {
        profileNameLabel.text = profile.fullName
        avatarView.isBusiness = profile.type == .business
        avatarView.updateWith(imageURL: profile.avatar?.formatted?.small, fullName: profile.fullName)
        activityStateView.isHidden = profile.isTyping
        typingStateLabel.isHidden = !profile.isTyping
        activityStateIndicator.backgroundColor = profile.isOnline ? R.color.accent3() : UIColor.white.withAlphaComponent(0.5)
        activityStateLabel.text = profile.isOnline ? "Online" : "Offline"
        activityStateLabel.textColor = profile.isOnline ? .white : UIColor.white.withAlphaComponent(0.5)
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.register(R.nib.privateOutcomeChatCell)
        tableView.register(R.nib.privateIncomeChatCell)
        tableView.register(R.nib.privateChatFileIncomeCell)
        tableView.register(R.nib.privateChatFileOutcomeCell)
        tableView.register(R.nib.privatePhotoVideoOutcomeCell)
        tableView.register(R.nib.privatePhotoVideoIncomeCell)
        tableView.register(R.nib.privateOutcomeChatVoiceCell)
        tableView.register(R.nib.privateIncomeChatVoiceCell)
        tableView.register(R.nib.unreadMarkCell)
        tableView.transform = CGAffineTransform(rotationAngle: .pi)
        tableView.scrollIndicatorInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: tableView.bounds.size.width - 8.0)
        tableView.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 12)
    }
    
    private func configureChatView() {
        chatView.delegate = self
        chatView.chatType = .private
        chatView.audioDelegate = self
    }
    
    private func configureLongTap() {
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(sender:)))
        view.addGestureRecognizer(longPressRecognizer)
    }
    
    private func formIsValid() -> Bool {
        var valid = true
        
        if let validationError = validation
            .validatePrivateMessageText(value: chatView.messageTextFieldView.text)
            .errorMessage(field: R.string.localizable.commentTitle()) {
            Toast.show(message: validationError.capitalizingFirstLetter())
            valid = false
            chatView.recordButton.isLoading = false
        }
        
        return valid
    }
    
    private func setChatBackground() {
        let imageView = UIImageView()
        tableView.backgroundView = imageView
        tableView.backgroundView?.transform = CGAffineTransform(rotationAngle: .pi)
        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage.chatBackground ?? R.image.chat_background_default()
    }

    private func openEditForm(message: PrivateChatMessageModel) {
        let attachment: ChatTextFieldView.Attachment? = {
            guard let attachment = message.attachment else {
                return nil
            }
            switch attachment.type {
            case .image:
                return .init(fileName: attachment.originName, attachment: .storedImage(attachment.origin))
            case .video:
                return .init(fileName: attachment.originName, attachment: .video(attachment.origin))
            case .voice:
                return .init(fileName: attachment.originName, attachment: .voice(attachment.origin))
            case .other:
                return .init(fileName: attachment.originName, attachment: .file(attachment.origin))
            }
        }()
        chatView.edit(messageID: message.id, text: message.text, attachment: attachment)
    }
    
    private func deleteMessageAction(message: PrivateChatMessageModel) {
        Alert(title:  R.string.localizable.deleteMessageAlert(), message:  R.string.localizable.deleteMessageAlert())
            .configure(doneText: Alert.Action.yes)
            .configure(cancelText: Alert.Action.no)
            .show { [weak self] (result) in
                if result == .done {
                    self?.viewModel.deleteMessage(message: message)
                }
        }
    }
    
    private func copyTextMessage(message: PrivateChatMessageModel) {
        UIPasteboard.general.string = message.text
    }
    
    // MARK: - Private actions
    @IBAction private func backButtonDidTap(_ sender: UIButton) {
        VoiceMessageManager.shared.stopPlaying()
        VoiceMessageManager.shared.stopSpeaking()
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func refreshData(_ sender: Any) {
        refreshControl.endRefreshing()
    }
    
    @IBAction func openPublicProfileButtonDidTap(_ sender: UIButton) {
        guard let opponent = viewModel.opponent else { return }
        
        switch opponent.type {
        case .basic:
            BasicProfileRouter(in: navigationController).openPublicProfileViewController(profileId: opponent.id)
        case .business:
            BusinessProfileRouter(in: navigationController).openPublicProfileController(id: opponent.id)
        }
    }
    
    @objc private func longPressed(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchPoint = sender.location(in: self.tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint),
               let message = viewModel.messageGroups[indexPath.section].messages[indexPath.row] as? PrivateChatMessageModel {
                openMenu(message: message)
                self.editedIndexPath = indexPath
            }
        }
    }

    private func openMenu(message: PrivateChatMessageModel) {
        guard message.menuActions.count > 0 else {
            return
        }
        let controller = EntityMenuController(entity: message)
        controller.onMenuSelected = { [weak self] (type, post) in
            guard let self = self else {
                return
            }
            switch type {
            case .edit:
                self.openEditForm(message: message)
            case .delete:
                self.deleteMessageAction(message: message)
            case .copy:
                self.copyTextMessage(message: message)
            default:
                break
            }
        }
        present(controller.alertController, animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension ChatDetailsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.messageGroups.count + 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == viewModel.messageGroups.count ? 0 : viewModel.messageGroups[section].messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: BaseChatCell!
        guard let message = viewModel.messageGroups[indexPath.section].messages[indexPath.row] as? PrivateChatMessageModel else {
            let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.unreadMarkCell, for: indexPath)!
            cell.transform = CGAffineTransform(rotationAngle: .pi)
            return cell
        }

        switch message.attachment?.type {
        case .image, .video:
            cell = message.isMy
                ? tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.privatePhotoVideoOutcomeCell, for: indexPath)
                : tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.privatePhotoVideoIncomeCell, for: indexPath)
            (cell as? BaseChatMediaCell)?.mediaDelegate = self
        case .voice:
            cell = message.isMy
            ? tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.privateOutcomeChatVoiceCell, for: indexPath)
            : tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.privateIncomeChatVoiceCell, for: indexPath)
        case .other:
            cell = message.isMy
            ? tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.privateChatFileOutcomeCell, for: indexPath)
                : tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.privateChatFileIncomeCell, for: indexPath)
        default:
            cell = message.isMy
            ? tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.privateOutcomeChatCell, for: indexPath)
                : tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.privateIncomeChatCell, for: indexPath)
        }
        (cell as? BaseChatTextCell)?.delegate = self
        cell.message = message
        cell.transform = CGAffineTransform(rotationAngle: .pi)

        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        if section == 0 {
            return UIView()
        }
        
        let label = DateHeaderLabel()
        label.backgroundColor = R.color.whiteTransparent()
        label.font = R.font.poppinsRegular(size: 12)
        
        if ArchiveService.shared.image != R.image.img1.name {
            label.text = getHeaderTitle(for: section)
            label.textColor = R.color.darkGrey()
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            
            let container = UIView()
            container.addSubview(label)
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor).isActive = true
            container.transform = CGAffineTransform(rotationAngle: .pi)
            
            return container
        } else {
            let sectionTitle = UILabel()
            sectionTitle.text = getHeaderTitle(for: section)
            sectionTitle.backgroundColor = R.color.greyBackground()
            sectionTitle.textAlignment = .center
            sectionTitle.textColor = R.color.darkGrey()
            sectionTitle.font = R.font.poppinsRegular(size: 12)
            sectionTitle.transform = CGAffineTransform(rotationAngle: .pi)
            
            return sectionTitle
        }
    }
    
    private func getHeaderTitle(for section: Int) -> String? {
        if section == 0 {
            return nil
        }
        let date = viewModel.messageGroups[section - 1].day

        if date.isToday == true {
            return R.string.localizable.todayHeaderTitle()
        }
        if date.isYesterday == true {
            return R.string.localizable.yesterdayHeaderTitle()
        }

        return date.dateString
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == viewModel.messageGroups.count - 1,
           let lastGroup = viewModel.messageGroups.last,
           indexPath.row == lastGroup.messages.count - 1 {
            viewModel.loadOlderMessages()
        }
        if let message = viewModel.messageGroups[indexPath.section].messages[indexPath.row] as? PrivateChatMessageModel {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.viewModel.readMessages(messages: [message])
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = tableView.cellForRow(at: indexPath)

        if let voiceCell = cell as? BaseChatVoiceCell, let audioURL = voiceCell.audioURL {
            VoiceMessageManager.shared.togglePlay(audioURL: audioURL)
            if let message = voiceCell.message {
                viewModel.listenVoice(message: message)
            }
        }

        tappedCell = cell
    }
}

// MARK: - ChatMessageSenderProtocol
extension ChatDetailsViewController: ChatMessageSenderProtocol {
    func didTapSend(text: String?, attachment: ChatTextFieldView.Attachment?) {
        let attachmentToSave = attachment?.attachment
        guard formIsValid() else {
            return
        }
        viewModel.sendMessage(text: text, attachment: attachmentToSave)
        chatView.clear()
    }

    func didTapUpdate(messageID: Int, text: String?, attachment: ChatTextFieldView.Attachment?) {
        let attachmentToSave = attachment?.attachment
        viewModel.updateMessage(messageID: messageID, text: text, attachment: attachmentToSave)
        chatView.clear()
        if let editedIndexPath = editedIndexPath {
            tableView.scrollToRow(at: editedIndexPath, at: .bottom, animated: true)
            self.editedIndexPath = nil
        }
    }

    func didTapAddAttachment() {
        self.mediaProcessor.openMediaOptions([
                                                .gallery(),
                                                .captureImage(),
                                                .captureVideo(),
                                                .file()])
    }

    func didTapRemoveAttachment() {
        viewModel.removeSelectedAttachment()
    }

    func didStartTyping() {
        viewModel.sendTyping(true)
    }

    func didEndTyping() {
        viewModel.sendTyping(false)
    }

//    func removeAttachment() {
//        currentAttachmentId = nil
//    }
//    
//    func updateHeightConstraints(height: CGFloat, isAttachExist: Bool) {
//        if height < GlobalConstants.Dimensions.spaceForAttachment {
//            chatViewHeightConstraint.constant = isAttachExist ? GlobalConstants.Dimensions.defineChatViewHeight() + GlobalConstants.Dimensions.spaceForAttachment : GlobalConstants.Dimensions.defineChatViewHeight()
//        } else if height < GlobalConstants.Dimensions.twoRowsHeight {
//            chatViewHeightConstraint.constant = isAttachExist ? GlobalConstants.Dimensions.oneRowHeight + GlobalConstants.Dimensions.defineChatViewHeight() + GlobalConstants.Dimensions.spaceForAttachment : GlobalConstants.Dimensions.oneRowHeight + GlobalConstants.Dimensions.defineChatViewHeight()
//        } else {
//            let heightWithAttach = GlobalConstants.Dimensions.oneRowHeight + GlobalConstants.Dimensions.defineChatViewHeight() + GlobalConstants.Dimensions.spaceForAttachment + GlobalConstants.Dimensions.oneRowHeight
//            chatViewHeightConstraint.constant = isAttachExist ? heightWithAttach : (GlobalConstants.Dimensions.oneRowHeight + GlobalConstants.Dimensions.defineChatViewHeight() + GlobalConstants.Dimensions.oneRowHeight)
//        }
//    }
//    
//    func updateTableViewBottomConstrain(isKeyboardIsShown: Bool) {
//        if actionType == .edit && pressedIndexPath != nil {
//            tableView.scrollToRow(at: pressedIndexPath!, at: .bottom, animated: true)
//        }
//    }
}

// MARK: - ChatAttachmentDelegate
extension ChatDetailsViewController: ChatAttachmentDelegate {
    func mediaDidSelected(media: ChatAttachmentModel) {
        switch media.type {
        case .image:
            MyPostsRouter(in: self.navigationController).openImage(imageUrl: media.origin)
        case .video:
            let player = AVPlayer(url: media.origin)
            let controller = AVPlayerViewController()
            controller.player = player
            controller.view.frame = self.view.frame
            
            present(controller, animated: true) {
                player.play()
            }
        default:
            break
        }
    }
}

// MARK: - LongPressDelegate
extension ChatDetailsViewController: LongPressDelegate {
    func recordActionDid(_ actionType: AudioRecordAction) {
        switch actionType {
        case .start:
            voiceManager.askAudioRecordingPermission { (granted) in
                if granted {
                    self.voiceManager.startRecording { (_, _) in }
                }
            }
        case .end:
            do {
                try self.voiceManager.stopRecording()
                guard let url = ArchiveService.shared.url else { return }
                self.viewModel.sendMessage(text: nil, attachment: .voice(url))
            } catch {
                (print("error"))
            }
        default:
            break
        }
    }
}

// MARK: - MediaProcessing

extension ChatDetailsViewController: MediaProcessorDelegate {
    func mediaOptionProcessed(result: MediaProcessingResult) {
        switch result {
        case .file(let url):
            viewModel.selectAttachment(.file(url))
            chatView.addAttachment(.init(fileName: nil, attachment: .file(url)))
        case .image(let image, let url):
            if let url = url {
                viewModel.selectAttachment(.storedImage(url))
                chatView.addAttachment(.init(fileName: nil, attachment: .storedImage(url)))
            } else {
                viewModel.selectAttachment(.capturedImage(image))
                chatView.addAttachment(.init(fileName: nil, attachment: .capturedImage(image)))
            }
        case .video(let url):
            let videoLength = NSData(contentsOf: url)?.length ?? 0

            if videoLength > GlobalConstants.Limits.videoFileLimit {
                Toast.show(message: R.string.localizable.bigVideoFileError())
                return
            } else {
                viewModel.selectAttachment(.video(url))
                chatView.addAttachment(.init(fileName: nil, attachment: .video(url)))
            }
        default:
            return
        }
    }
}

extension ChatDetailsViewController: BaseChatTextCellDelegate {
    func openProfile(id: Int) {
        profileNavigationResolver.openProfile(profileId: id)
    }
}
