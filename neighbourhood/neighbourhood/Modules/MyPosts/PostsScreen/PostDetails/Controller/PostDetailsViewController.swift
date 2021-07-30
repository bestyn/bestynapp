//
//  PostDetailsViewController.swift
//  neighbourhood
//
//  Created by Dioksa on 01.06.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import AVKit
import MobileCoreServices

let headerHeight: CGFloat = 30.0

enum TypeOfAttachment: String, Codable {
    case image, video, other, voice
}

protocol PrivateProfileDelegate: AnyObject {
    func goToCurrentProfile()
}

struct MessageGroup {
    let day: Date
    var messages: [ChatMessageModel]
}

final class PostDetailsViewController: BaseViewController {
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var chatView: ChatTextFieldView!
    @IBOutlet private weak var chatViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var chatBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var editedMessageView: UIView!
    @IBOutlet private weak var editMessageLabel: UILabel!
    @IBOutlet private weak var closeMessageButton: UIButton!
    @IBOutlet private weak var titleScreenLabel: UILabel!
    
    private var messagesFromServer = [ChatMessageModel]()
    private var arrayOfChats = [MessageGroup]()
    private let validation = ValidationManager()
    
    private var currentPost: PostModel!
    private var postId: Int!
    private var postType: TypeOfPost = .general
    private var pressedIndexPath: IndexPath?
    private var lastMessageId: Int?
    private var currentAttachmentId: Int?
    
    private var type: TypeOfAttachment?
    private var actionType: TypeOfScreenAction = .create
    private var fileUrl: URL?
    private var imageAttachment: UIImage?
    private var videoAttachment: URL?
    private var expandedComments: [IndexPath: Bool] = [:]

    private var currentProfileID: Int {
        ArchiveService.shared.currentProfile!.id
    }
    
    private lazy var postsManager: RestMyPostsManager = {
        let manager = RestService.shared.createOperationsManager(from: self, type: RestMyPostsManager.self)
        manager.assignErrorHandler { [weak self] (error) in
            self?.handleError(error)
        }
        return manager
    }()
    private lazy var chatManager: RestChatManager = {
        let manager = RestService.shared.createOperationsManager(from: self, type: RestChatManager.self)
        manager.assignErrorHandler { [weak self] (error) in
            self?.handleError(error)
        }
        return manager
    }()
    lazy var reactionsManager: RestReactionsManager = {
        let manager = RestService.shared.createOperationsManager(from: self, type: RestReactionsManager.self)
        manager.assignErrorHandler { [weak self] (error) in
            self?.handleError(error)
        }
        return manager
    }()
    lazy var profileManager: RestProfileManager = {
        let manager = RestService.shared.createOperationsManager(from: self, type: RestProfileManager.self)
        manager.assignErrorHandler { [weak self] (error) in
            self?.handleError(error)
        }
        return manager
    }()

    lazy var businesProfileManager: RestBusinessProfileManager = {
        let manager = RestService.shared.createOperationsManager(from: self, type: RestBusinessProfileManager.self)
        manager.assignErrorHandler { [weak self] (error) in
            self?.handleError(error)
        }
        return manager
    }()

    private lazy var mediaProcessor: MediaProcessor = MediaProcessor(viewController: self, delegate: self)
    private var tapRecognizer = UITapGestureRecognizer(target: self, action: nil)
    private var isMenuButtonTapped = false

    weak var profileDelegate: PrivateProfileDelegate?
    weak var postUpdateDelegate: PostFormDelegate?
    
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    
    init(currentPost: PostModel) {
        self.currentPost = currentPost
        self.postId = currentPost.id
        super.init(nibName: nil, bundle: nil)
    }

    init(postId: Int) {
        self.postId = postId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setDelegates()
        
        configureTableView()
        chatView.chatType = .public
        getAllMessages()
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(sender:)))
        view.addGestureRecognizer(longPressRecognizer)
        
        setupRealtimeListeners()

        NotificationCenter.default.addObserver(self, selector: #selector(profileChanged), name: .profileDidChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(postUpdated(notification:)), name: .postUpdated, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if currentPost != nil {
            titleScreenLabel.text = currentPost.type.detailsTitle
        }
        fetchUpdatedPost()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AudioPlayerService.shared.stop()
    }
    
    private func setupRealtimeListeners() {
        RealtimeService.shared.listen(channel: RealtimeService.Channel.postComments(postID: postId)) { [weak self] (message) in
            guard let strongSelf = self,
                let chatMessageModel = message.model(of: RealtimeChatUpdateModel.self) else {
                    return
            }
            
            switch chatMessageModel.action {
            case .create:
                strongSelf.createMessage(chatMessageModel)
            case .delete:
                strongSelf.deleteMessage(chatMessageModel.data)
            case .update:
                strongSelf.updateMessage(chatMessageModel)
            }
        }
    }
    
    private func createMessage(_ chatMessageModel: RealtimeChatUpdateModel) {
        if arrayOfChats.isEmpty {
            DispatchQueue.main.async {
                self.arrayOfChats = [MessageGroup(day: chatMessageModel.data.createdAt, messages: [chatMessageModel.data])]
                self.tableView.reloadData()
            }
        } else {
            arrayOfChats[0].messages.insert(chatMessageModel.data, at: 0)
            messagesFromServer.append(chatMessageModel.data)
            groupMessages()
        }
        
        fetchUpdatedPost()
    }
    
    private func deleteMessage(_ chatMessageModel: ChatMessageModel) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let section = self.arrayOfChats.first(where: { $0.messages.contains(where: { $0.id == chatMessageModel.id })})
            guard let sectionIndex = self.arrayOfChats.firstIndex(where: { $0.day == section?.day }) else {
                return
            }
            
            if self.arrayOfChats.count == 1 && self.arrayOfChats.first?.messages.isEmpty ?? true {
                self.arrayOfChats = []
                self.tableView.reloadData()
            } else {
                guard let indexToDelete = self.arrayOfChats[sectionIndex].messages.firstIndex(where: { $0.id == chatMessageModel.id }) else { return }
                self.arrayOfChats[sectionIndex].messages.remove(at: indexToDelete)
                self.messagesFromServer.removeAll(where: { $0.id == chatMessageModel.id })
                
                if self.arrayOfChats.count == 1 && self.arrayOfChats.first?.messages.isEmpty ?? true {
                    self.arrayOfChats = []
                    self.tableView.reloadData()
                }
            }

            
            self.fetchUpdatedPost()
        }
    }
    
    private func updateMessage(_ chatMessageModel: RealtimeChatUpdateModel) {
        let section = arrayOfChats.first(where: { $0.messages.contains(where: { $0.id == chatMessageModel.data.id })})
        
        guard let sectionIndex = arrayOfChats.firstIndex(where: { $0.day == section?.day }), let indexToUpdate = arrayOfChats[sectionIndex].messages.firstIndex(where: { $0.id == chatMessageModel.data.id }) else { return }
        
        arrayOfChats[sectionIndex].messages[indexToUpdate] = chatMessageModel.data
        
        if let index = messagesFromServer.firstIndex(where: { $0.id == chatMessageModel.data.id }) {
            messagesFromServer[index] = chatMessageModel.data
        }
        
        groupMessages()
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    private func setDelegates() {
        chatView.delegate = self
    }
    
    private func configureTableView() {
        tableView.register(R.nib.postCell)
        tableView.register(R.nib.emptyChatCell)
        tableView.register(R.nib.publicChatCell)
        tableView.register(R.nib.publicOutcomeChatCell)
        tableView.register(R.nib.chatFileIncomeCell)
        tableView.register(R.nib.chatFileOutcomeCell)
        tableView.register(R.nib.photoVideoOutcomeCell)
        tableView.register(R.nib.photoVideoIncomeCell)
        tableView.refreshControl = refreshControl
        tableView.estimatedRowHeight = 100
        tableView.sectionFooterHeight = 0
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    }
    
    private func groupMessages() {
        guard !messagesFromServer.isEmpty else { return }
        arrayOfChats = []
        
        let groups: [Date: [ChatMessageModel]] = .init(grouping: messagesFromServer.sorted(by: {$1.createdAt > $0.createdAt}), by: { $0.createdAt.midnight })
        arrayOfChats = groups.map({ MessageGroup(day: $0, messages: $1.reversed())}).sorted(by: {$0.day > $1.day})
    }
    
    private func clearAttachment() {
        currentAttachmentId = nil
        imageAttachment = nil
        videoAttachment = nil
        fileUrl = nil
        type = nil
    }
    
    // MARK: - Private actions
    @IBAction private func backButtonDidTap(_ sender: UIButton) {
        postUpdateDelegate?.postUpdated(post: currentPost)
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func refreshData(_ sender: Any) {
        fetchUpdatedPost()
        messagesFromServer = []
        expandedComments = [:]
        getAllMessages(needsToDeleteHistory: true)
        clearAttachment()
    }

    @objc private func postUpdated(notification: Notification) {
        if let post = notification.object as? PostModel {
            self.currentPost = post
            self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
        }
    }

    @objc private func profileChanged() {
        let newAvatar = ArchiveService.shared.currentProfile?.avatar
        if currentPost.isMy {
            currentPost.profile?.avatar = newAvatar
        }
        messagesFromServer = messagesFromServer.map({ message -> ChatMessageModel in
            var message = message
            message.profile?.avatar = newAvatar
            return message
        })

        arrayOfChats = arrayOfChats.map({ (messageGroup) -> MessageGroup in
            var messageGroup = messageGroup
            messageGroup.messages = messageGroup.messages.map({ message -> ChatMessageModel in
                var message = message
                message.profile?.avatar = newAvatar
                return message
            })
            return messageGroup
        })
        tableView.reloadData()
    }
    
    @objc private func longPressed(sender: UILongPressGestureRecognizer) {
        guard sender.state == UIGestureRecognizer.State.began else {
            return
        }
        let touchPoint = sender.location(in: self.tableView)
        guard let indexPath = tableView.indexPathForRow(at: touchPoint),
              indexPath.section != 0 else {
            return
        }
        let message = arrayOfChats[indexPath.section - 1].messages[indexPath.row]

        let controller = EntityMenuController(entity: message)
        controller.onMenuSelected = { [weak self] (type, message) in
            guard let self = self else {
                return
            }
            switch type {
            case .edit:
                self.actionType = .edit
                self.openEditForm(message: message)
            case .delete:
                self.deleteMessageAction(message: message)
            case .copy:
                self.copyText(message: message)
            default:
                break
            }
        }
        present(controller.alertController, animated: true)

    }

    private func formIsValid() -> Bool {
        var valid = true

        if let validationError = validation
            .validateMessageText(value: chatView.messageTextFieldView.text)
            .errorMessage(field: R.string.localizable.commentTitle()) {
            Toast.show(message: validationError.capitalizingFirstLetter())
            valid = false
            chatView.recordButton.isLoading = false
        }

        return valid
    }
}

// MARK: - REST requests
private extension PostDetailsViewController {
    /// --------------------------- First section - post cell ---------------------------
    func fetchUpdatedPost() {

        postsManager.getPost(postId: postId)
            .onStateChanged { [weak self] (state) in
                if  state == .ended {
                    DispatchQueue.main.async {
                        self?.refreshControl.endRefreshing()
                    }
                }
        } .onComplete { [weak self] (result) in
            guard let self = self, let post = result.result else { return }
            self.currentPost = post
            self.titleScreenLabel.text = post.type.detailsTitle
            self.tableView.reloadData()
            NotificationCenter.default.post(name: .postUpdated, object: post)
        } .run()
    }

    
    func addFollowToPost(_ postId: Int, _ postType: TypeOfPost) {

        if currentPost.iFollow == false {
            postsManager.followPost(postId: postId)
                .onComplete { [weak self] (result) in
                    guard let strongSelf = self else { return }
                    strongSelf.fetchUpdatedPost()
            } .run()
        }
    }
    
    func deletePost(_ post: PostModel) {
        Alert(title: post.type.deleteAlertTitle, message: Alert.Message.deletedPostMessage)
            .configure(doneText: R.string.localizable.yesButtonTitle())
            .configure(cancelText: R.string.localizable.noButtonTitle())
            .show() { [weak self] (result) in
                guard let strongSelf = self else { return }
                
                switch result {
                case .done:
                    strongSelf.deletePostFromServer(post: post)
                default:
                    break
                }
        }
    }
    
    func deletePostFromServer(post: PostModel) {
        postsManager.deletePost(postId: post.id)
         .onComplete { [weak self] (_) in
            guard let self = self else { return }
            self.postUpdateDelegate?.postRemoved(post: post)
            self.navigationController?.popViewController(animated: true)
            Toast.show(message: post.type.deleteSuccessMessage)
        } .run()
    }
    
    func deleteFollowFromPost(post: PostModel) {
        postsManager.unfollowPost(postId: post.id)
            .onComplete { [weak self] (result) in
                guard let strongSelf = self else { return }
                strongSelf.fetchUpdatedPost()
        } .run()
    }
    
    /// ---------------------------All other sections with chat cells ---------------------------
    func getAllMessages(needsToDeleteHistory: Bool = false, needsToScroll: Bool = true) {
        let lastMessageId = needsToDeleteHistory ? nil : self.lastMessageId
        chatManager.getChatMessages(postId: postId, lastId: lastMessageId)
            .onComplete { [weak self] (result) in
                guard let self = self, let model = result.result else { return }
                if needsToDeleteHistory {
                    self.messagesFromServer = []
                }

                self.lastMessageId = model.reversed().last?.id
                
                if !self.messagesFromServer.contains(where: { $0.id == model.first?.id }) {
                    self.messagesFromServer.append(contentsOf: model)
                }
                
                self.groupMessages()
                self.tableView.reloadData()
                
                if needsToScroll {
                    self.tableView.scrollToTop()
                }
        } .run()
    }
    
    func sendMessage(data: ChatAttach) {

        chatManager.sendMessage(data: data)
            .onStateChanged({ [weak self] (state) in
                switch state {
                case .started:
                    self?.chatView.recordButton.isLoading = true
                case .ended:
                    self?.chatView.recordButton.isLoading = false
                }
            })
            .onComplete { [weak self] _ in
                guard let self = self else { return }
                self.actionType = .create
                self.getAllMessages(needsToDeleteHistory: true)
                self.clearAttachment()
                self.fetchUpdatedPost()
                AnalyticsService.logCommentAdded()
        }.run()
    }
    
    func updatePostMessage(messageID: Int, text: String?, attachmentID: Int?) {

        let data = ChatAttach(
            text: text,
            attachmentId: attachmentID,
            messageId: messageID,
            postId: nil,
            profileId: currentProfileID)

        chatManager.editMessage(data: data)
            .onStateChanged({ [weak self] (state) in
                switch state {
                case .started:
                    self?.chatView.recordButton.isLoading = true
                case .ended:
                    self?.chatView.recordButton.isLoading = false
                }
            })
            .onComplete { [weak self] (result) in
                guard let strongSelf = self, let chatMessage = result.result else { return }
                strongSelf.chatView.clear()
                strongSelf.messagesFromServer = strongSelf.messagesFromServer.map({ (message) -> ChatMessageModel in
                    if message.id == chatMessage.id {
                        return chatMessage
                    }
                    return message
                })
                strongSelf.groupMessages()
                strongSelf.tableView.reloadData()
        } .run()
    }

    func addAttachment(completion: @escaping (ChatAttachmentModel) -> Void) {
        chatManager.addAttachment(fileUrl: fileUrl, image: imageAttachment, videoUrl: videoAttachment)
            .onComplete { (result) in
                if let attachment = result.result {
                    completion(attachment)
                }
        } .run()
    }
    
    func deleteChatMessage(message: ChatMessageModel) {
        chatManager.deleteMessage(messageId: message.id)
            .onComplete { [weak self] _ in
                guard let self = self else {
                    return
                }
                self.deleteMessage(message)
                self.fetchUpdatedPost()
        }
        .run()
    }
    
    func defineMessageText() -> String? {
        var text: String?
        
        if chatView.messageTextFieldView.text == R.string.localizable.addCommentPlaceholder() {
            text = nil
        } else {
            text = chatView.messageTextFieldView.text
        }
        
        return text?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func restAddReaction(post: PostModel, reaction: Reaction) {
        reactionsManager.addReaction(postID: post.id, reaction: reaction)
            .onComplete { [weak self] (_) in
                self?.fetchUpdatedPost()
            }.run()
    }

    private func restRemoveReaction(post: PostModel) {
        reactionsManager.removeReaction(postID: post.id)
            .onComplete { [weak self] (_) in
                self?.fetchUpdatedPost()
            }.run()
    }

    private func restSetAsAvatar(image: UIImage) {
        guard let currentProfile = ArchiveService.shared.currentProfile else {
            return
        }
        if currentProfile.type == .business {
            businesProfileManager.updateProfile(id: currentProfile.id, data: nil, image: image)
                .onComplete { (result) in
                    if let profile = result.result {
                        var user = ArchiveService.shared.userModel
                        let businessProfiles = user?.businessProfiles?.map({ (businesProfile) -> BusinessProfile in
                            if businesProfile.id == profile.id {
                                return profile
                            }
                            return businesProfile
                        })
                        user?.businessProfiles = businessProfiles
                        ArchiveService.shared.userModel = user
                        ArchiveService.shared.currentProfile = profile.selectorProfile
                        Toast.show(message: R.string.localizable.avatarChanged())
                    }
                }.run()
        } else {
            profileManager.changeUserProfile(data: nil, image: image)
                .onComplete { (result) in
                    if let profile = result.result {
                        var user = ArchiveService.shared.userModel
                        user?.profile = profile
                        ArchiveService.shared.userModel = user
                        ArchiveService.shared.currentProfile = profile.selectorProfile
                        Toast.show(message: R.string.localizable.avatarChanged())
                    }
                }.run()
        }
    }

    private func restViewMedia(media: MediaDataModel) {
        postsManager.viewMedia(mediaId: media.id).run()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension PostDetailsViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if arrayOfChats.isEmpty {
            return 1
        } else {
            return arrayOfChats.count + 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard !arrayOfChats.isEmpty else {
            return 2
        }
        
        switch section {
        case 0:
            return 1
        default:
            return arrayOfChats[section - 1].messages.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        if arrayOfChats.isEmpty {
            switch indexPath.row {
            case 0:
                return showFirstCell(by: indexPath)
            default:
                cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.emptyChatCell, for: indexPath)
            }
        } else {
            switch (indexPath.section, indexPath.row) {
            case (0, 0):
                return showFirstCell(by: indexPath)
            default:
                let message = arrayOfChats[indexPath.section - 1].messages[indexPath.row]
                let isIncomingMessage = message.profile?.id != currentProfileID
                let isAttachmentExist = message.attachment != nil
                let attachmentType = message.attachment?.type
                
                if isIncomingMessage && !isAttachmentExist {
                    cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.publicChatCell, for: indexPath)
                    (cell as? BasePostCommentTextCell)?.expanded = expandedComments[indexPath] ?? false
                    (cell as? PublicChatCell)?.message = message
                    (cell as? PublicChatCell)?.delegate = self
                    (cell as? PublicChatCell)?.layoutIfNeeded()
                } else if isIncomingMessage && isAttachmentExist && attachmentType != .other {
                    cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.photoVideoIncomeCell, for: indexPath)
                    (cell as? BasePostCommentTextCell)?.expanded = expandedComments[indexPath] ?? false
                    (cell as? PhotoVideoIncomeCell)?.message = message
                    (cell as? PhotoVideoIncomeCell)?.delegate = self
                    (cell as? PhotoVideoIncomeCell)?.mediaDelegate = self
                    (cell as? PhotoVideoIncomeCell)?.layoutIfNeeded()
                } else if isIncomingMessage && isAttachmentExist {
                    cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.chatFileIncomeCell, for: indexPath)
                    (cell as? BasePostCommentTextCell)?.expanded = expandedComments[indexPath] ?? false
                    (cell as? ChatFileIncomeCell)?.message = message
                    (cell as? ChatFileIncomeCell)?.delegate = self
                    (cell as? ChatFileIncomeCell)?.layoutIfNeeded()
                    
                } else if !isIncomingMessage && isAttachmentExist && attachmentType != .other {
                    cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.photoVideoOutcomeCell, for: indexPath)
                    (cell as? BasePostCommentTextCell)?.expanded = expandedComments[indexPath] ?? false
                    (cell as? PhotoVideoOutcomeCell)?.message = message
                    (cell as? PhotoVideoOutcomeCell)?.delegate = self
                    (cell as? PhotoVideoOutcomeCell)?.mediaDelegate = self
                    (cell as? PhotoVideoOutcomeCell)?.layoutIfNeeded()
                } else if !isIncomingMessage && attachmentType == .other {
                    cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.chatFileOutcomeCell, for: indexPath)
                    (cell as? BasePostCommentTextCell)?.expanded = expandedComments[indexPath] ?? false
                    (cell as? ChatFileOutcomeCell)?.message = message
                    (cell as? ChatFileOutcomeCell)?.delegate = self
                    (cell as? ChatFileOutcomeCell)?.layoutIfNeeded()
                } else if !isIncomingMessage && !isAttachmentExist {
                    cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.publicOutcomeChatCell, for: indexPath)
                    (cell as? BasePostCommentTextCell)?.expanded = expandedComments[indexPath] ?? false
                    (cell as? PublicOutcomeChatCell)?.message = message
                    (cell as? PublicOutcomeChatCell)?.delegate = self
                    (cell as? PublicOutcomeChatCell)?.layoutIfNeeded()
                }
            }
        }
        
        guard let postCell = cell else {
            NSLog("🔥 Error occurred while creating Chat Cells")
            return UITableViewCell() }
        
        return postCell
    }
    
    private func showFirstCell(by index: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.postCell, for: index)!
        cell.actionDelegate = self
        cell.cellDelegate = self
        cell.post = currentPost
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0.00001
        } else if arrayOfChats[section - 1].messages.count == 0 {
            return 0.00001
        } else {
            return headerHeight
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return nil
        } else {
            if let firstMessageInSection = arrayOfChats[section - 1].messages.first {
                let createdAt = firstMessageInSection.createdAt
                let sectionTitle = UILabel()
                
                if createdAt.isToday == true {
                    sectionTitle.text = R.string.localizable.todayHeaderTitle()
                } else if createdAt.isYesterday == true {
                    sectionTitle.text = R.string.localizable.yesterdayHeaderTitle()
                } else {
                    sectionTitle.text = createdAt.dateString
                }
                
                sectionTitle.backgroundColor = R.color.greyBackground()
                sectionTitle.textAlignment = .center
                sectionTitle.textColor = R.color.darkGrey()
                sectionTitle.font = R.font.poppinsRegular(size: 12)
                return sectionTitle
            }
            
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard !arrayOfChats.isEmpty else { return }
        
        if indexPath.row == (arrayOfChats.last?.messages.count)! - 1 && arrayOfChats.last?.messages.last?.id == lastMessageId {
            getAllMessages(needsToScroll: false)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.visibleCells.forEach({ ($0 as? BasePostCell)?.hideReactions() })
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: .zero)
    }
}

// MARK: - PostCellDelegate
extension PostDetailsViewController: PostCellDelegate {
    func reactionSelected(_ reaction: Reaction, for post: PostModel) {
        restAddReaction(post: post, reaction: reaction)
    }

    func reactionRemoved(for post: PostModel) {
        restRemoveReaction(post: post)
    }


    func openMedia(_ media: MediaDataModel) {
        if media.type == .image {
            MyPostsRouter(in: navigationController).openImage(imageUrl: media.origin)
            return
        }
        if media.type == .video {
            MyPostsRouter(in: navigationController).openVideo(videoURL: media.origin)
        }
    }

    func reloadDescriptionLabel(post: PostModel) {
        UIView.performWithoutAnimation {
            tableView.beginUpdates()
            tableView.endUpdates()
            tableView.layer.removeAllAnimations()
        }
    }

    func openProfile(post: PostModel) {
        if post.isMy {
            showCurrentProfilePage()
            return
        }
        guard let profile = post.profile else {
            return
        }
        switch profile.type {
        case .basic:
            BasicProfileRouter(in: navigationController).openPublicProfileViewController(profileId: profile.id)
        case .business:
            BusinessProfileRouter(in: navigationController).openPublicProfileController(id: profile.id)
        }
    }
    
    func followPost(_ post: PostModel) {
        addFollowToPost(post.id, post.type)
    }
    
    func showCurrentProfilePage() {
        MainScreenRouter(in: navigationController).openMyProfile()
    }
    
    func openDetailsScreen(post: PostModel) {}

    func openReactions(post: PostModel) {
        BottomMenuPresentationManager.present(ReactionsListViewController(post: post), from: self)
    }

    func hashtagSelected(_ hashtag: String) {
        MyPostsRouter(in: navigationController).openHashtagPage(hashtag: hashtag)
    }

    func mentionSelected(profileId: Int) {
        profileNavigationResolver.openProfile(profileId: profileId)
    }

    func mediaViewed(media: MediaDataModel) {
        restViewMedia(media: media)
    }
}

// MARK: - MenuActionButtonDelegate
extension PostDetailsViewController: MenuActionButtonDelegate {
    func openMenu(post: PostModel) {
        let controller = EntityMenuController(entity: post)
        controller.onMenuSelected = { [weak self] (type, post) in
            guard let self = self else {
                return
            }
            switch type {
            case .edit:
                if post.type == .story {
                    CreateStoryRouter(in: self.navigationController).openEditStory(storyPost: post)
                } else {
                    if PostSaver.shared.checkPostFormAvailability() {
                        BasicProfileRouter(in: self.navigationController).openEditPost(post: post, delegate: self)
                    }
                }
            case .unfollow:
                self.deleteFollowFromPost(post: post)
            case .delete:
                self.deletePost(post)
            case .report:
                BasicProfileRouter(in: self.navigationController).openReportViewController(for: post)
            case .copy:
                self.copyText(post: post)
            case .setAsAvatar:
                self.setAsAvatar(post)
            case .openChat:
                if let profile = post.profile?.chatProfile {
                    ChatRouter(in: self.navigationController).opeChatDetailsViewController(with: profile)
                }
            default:
                break
            }
        }
        present(controller.alertController, animated: true)
    }

    private func setAsAvatar(_ post: PostModel) {
        guard post.type == .media,
              let imageURL = post.media?.first?.formatted?.medium else {
            return
        }
        UIImage.load(from: imageURL) { [weak self] (image) in
            if let image = image {
                self?.restSetAsAvatar(image: image)
            }
        }
    }
}

// MARK: - BottomTabsSwitcherDelegate
extension PostDetailsViewController: PostFormDelegate {
    func newPostAdded(post: PostModel) {}

    func postUpdated(post: PostModel) {
    }
    
    func postRemoved(post: PostModel) {}
}

// MARK: - ChatMessageSenderProtocol

extension PostDetailsViewController: ChatMessageSenderProtocol {
    func didTapSend(text: String?, attachment: ChatTextFieldView.Attachment?) {
        guard let currentProfile = ArchiveService.shared.currentProfile else {
            return
        }
        guard formIsValid() else {
            return
        }
        let postId = self.postId
        if let attachment = attachment, attachment.id == nil {
            chatView.recordButton.isLoading = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                self.addAttachment { [weak self] (savedAttachment) in
                    self?.chatView.clear()
                    self?.sendMessage(data: ChatAttach(text: text, attachmentId: savedAttachment.id, messageId: nil, postId: postId, profileId: currentProfile.id))
                }

            }

        } else {
            chatView.recordButton.isLoading = true
            chatView.clear()
            sendMessage(data: ChatAttach(text: text, attachmentId: nil, messageId: nil, postId: postId, profileId: currentProfile.id))
        }
    }

    func didTapUpdate(messageID: Int, text: String?, attachment: ChatTextFieldView.Attachment?) {
        if let attachment = attachment, attachment.id == nil {
            chatView.recordButton.isLoading = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                self.addAttachment { [weak self] (savedAttachment) in
                    self?.chatView.clear()
                    self?.updatePostMessage(messageID: messageID, text: text, attachmentID: savedAttachment.id)
                }

            }

        } else {
            chatView.recordButton.isLoading = true
            chatView.clear()
            updatePostMessage(messageID: messageID, text: text, attachmentID: attachment?.id)
        }
    }

    func didTapAddAttachment() {
        self.mediaProcessor.openMediaOptions([.gallery(), .captureImage(), .captureVideo(), .file()])
    }

    func didTapRemoveAttachment() {
        currentAttachmentId = nil
    }

    func didStartTyping() {
        
    }

    func didEndTyping() {

    }
}

// MARK: - Enitities actions

extension PostDetailsViewController {
    
    private func openEditForm(message: ChatMessageModel) {
        let attachment: ChatTextFieldView.Attachment? = {
            guard let attachment = message.attachment else {
                return nil
            }
            return .from(attachment)
        }()
        chatView.edit(messageID: message.id, text: message.text, attachment: attachment)
    }

    private func deleteMessageAction(message: ChatMessageModel) {
        Alert(title: R.string.localizable.deleteMessageAlertTitle(), message: R.string.localizable.deleteMessageAlert())
            .configure(doneText: Alert.Action.yes)
            .configure(cancelText: Alert.Action.no)
            .show { [weak self] (result) in
                if result == .done {
                    self?.deleteChatMessage(message: message)
                }
        }
    }
    
    private func copyText(message: ChatMessageModel) {
        UIPasteboard.general.string = message.text
    }
    private func copyText(post: PostModel) {
        UIPasteboard.general.string = post.description
    }
}

extension PostDetailsViewController: PostCommentCellDelegate {
    func profileSelected(for message: ChatMessageModel) {
        guard let profile = message.profile else {
            return
        }
        if profile.id == ArchiveService.shared.currentProfile?.id {
            showCurrentProfilePage()
            return
        }
        if profile.type == .basic {
            BasicProfileRouter(in: navigationController).openPublicProfileViewController(profileId: profile.id)
        } else {
            BusinessProfileRouter(in: navigationController).openPublicProfileController(id: profile.id)
        }
    }

    func cellNeedResize(cell: BasePostCommentCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            expandedComments[indexPath] = true
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
}

extension PostDetailsViewController: ChatAttachmentDelegate {
    func mediaDidSelected(media: ChatAttachmentModel) {
        switch media.type {
        case .image:
            MyPostsRouter(in: navigationController).openImage(imageUrl: media.origin)
        case .video:
            MyPostsRouter(in: navigationController).openVideo(videoURL: media.origin)
        default:
            break
        }
    }
}

// MARK: - MediaProcessing

extension PostDetailsViewController: MediaProcessorDelegate {
    func mediaOptionProcessed(result: MediaProcessingResult) {
        switch result {
        case .image(let image, let url):
            type = .image
            imageAttachment = image
            if let url = url {
                chatView.addAttachment(.init(fileName: nil, attachment: .storedImage(url)))
            } else {
                chatView.addAttachment(.init(fileName: nil, attachment: .capturedImage(image)))
            }

        case .video(let url):
            type = .video
            let videoLength = NSData(contentsOf: url)?.length ?? 0

            if videoLength > GlobalConstants.Limits.videoFileLimit {
                Toast.show(message: R.string.localizable.bigVideoFileError())
                return
            } else {
                videoAttachment = url
                chatView.addAttachment(.init(fileName: nil, attachment: .video(url)))
            }
        case .file(let url):
            type = .other
            fileUrl = url
            chatView.addAttachment(.init(fileName: nil, attachment: .file(url)))
        default:
            return
        }
    }
}
