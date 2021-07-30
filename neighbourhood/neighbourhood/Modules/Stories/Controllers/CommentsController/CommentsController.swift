//
//  CommentsController.swift
//  neighbourhood
//
//  Created by iphonovv on 26.11.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

class CommentsController: BaseViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var chatView: ChatTextFieldView!
    @IBOutlet weak var chatViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var chatBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var editedMessageView: UIView!
    @IBOutlet weak var editMessageLabel: UILabel!
    @IBOutlet weak var closeMessageButton: UIButton!
    
    var messagesFromServer = [ChatMessageModel]()
    var arrayOfChats = [MessageGroup]()
    let validation = ValidationManager()
    
    var currentPost: PostModel
    var postId: Int?
    var postType: TypeOfPost = .story
    var pressedIndexPath: IndexPath?
    var lastMessageId: Int?
    var currentAttachmentId: Int?
    
    var type: TypeOfAttachment?
    var actionType: TypeOfScreenAction = .create
    var fileUrl: URL?
    var imageAttachment: UIImage?
    var videoAttachment: URL?
    var expandedComments: [IndexPath: Bool] = [:]

    var withPost: Bool = true
    
    var currentProfileID: Int {
        ArchiveService.shared.currentProfile!.id
    }
    
    lazy var mediaProcessor: MediaProcessor = MediaProcessor(viewController: self, delegate: self)
    
    lazy var postsManager: RestMyPostsManager = {
        let manager = RestService.shared.createOperationsManager(from: self, type: RestMyPostsManager.self)
        manager.assignErrorHandler { [weak self] (error) in
            self?.handleError(error)
        }
        return manager
    }()
    
    lazy var chatManager: RestChatManager = {
        let manager = RestService.shared.createOperationsManager(from: self, type: RestChatManager.self)
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
    
    lazy var profileManager: RestProfileManager = {
        let manager = RestService.shared.createOperationsManager(from: self, type: RestProfileManager.self)
        manager.assignErrorHandler { [weak self] (error) in
            self?.handleError(error)
        }
        return manager
    }()
    
    init(currentPost: PostModel) {
        self.currentPost = currentPost
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if withPost {
            fetchUpdatedPost()
        }
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
        guard let indexPath = tableView.indexPathForRow(at: touchPoint) else {
            return
        }
        if withPost, indexPath.section == 0 {
            return
        }
        let message = arrayOfChats[indexPath.section - (withPost ? 1 : 0)].messages[indexPath.row]

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

    
    private func setupRealtimeListeners() {
        RealtimeService.shared.listen(channel: RealtimeService.Channel.postComments(postID: self.currentPost.id)) { [weak self] (message) in
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
            NotificationCenter.default.post(name: .postCommentsUpdated, object: strongSelf.currentPost)
        }
    }
    
    @objc private func refreshData(_ sender: Any) {
        if withPost {
            fetchUpdatedPost()
        }
        messagesFromServer = []
        expandedComments = [:]
        getAllMessages(needsToDeleteHistory: true)
        clearAttachment()
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
            self.tableView.reloadData()
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
}

// MARK: - REST requests
private extension CommentsController {
    /// --------------------------- First section - post cell ---------------------------
    func fetchUpdatedPost() {
        postsManager.getPost(postId: currentPost.id)
            .onStateChanged { [weak self] (state) in
                if  state == .ended {
                    DispatchQueue.main.async {
                        self?.refreshControl.endRefreshing()
                    }
                }
        } .onComplete { (result) in
            guard let post = result.result else { return }
            NotificationCenter.default.post(name: .postUpdated, object: post)
        } .run()
    }
    
    /// ---------------------------All other sections with chat cells ---------------------------
    func getAllMessages(needsToDeleteHistory: Bool = false, needsToScroll: Bool = true) {
        let lastMessageId = needsToDeleteHistory ? nil : self.lastMessageId
        chatManager.getChatMessages(postId: currentPost.id, lastId: lastMessageId)
            .onStateChanged { [weak self] (state) in
                if  state == .ended {
                    DispatchQueue.main.async {
                        self?.refreshControl.endRefreshing()
                    }
                }
            }
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
                
                if needsToScroll, self.messagesFromServer.count > 0 {
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
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension CommentsController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if arrayOfChats.isEmpty {
            return withPost ? 2 : 1
        } else {
            return arrayOfChats.count + (withPost ? 1 : 0)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard !arrayOfChats.isEmpty else {
            return withPost ? 2 : 1
        }
        
        switch section {
        case 0:
            if withPost {
                return 1
            } else {
                fallthrough
            }
        default:
            return arrayOfChats[section - (withPost ? 1 : 0)].messages.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        if arrayOfChats.isEmpty {
            switch indexPath.row {
            case 0:
                if withPost {
                    return showFirstCell(by: indexPath)
                } else {
                    fallthrough
                }
            default:
                return tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.emptyChatCell, for: indexPath)!
            }
        } else {
            switch (indexPath.section, indexPath.row) {
            case (0, 0):
                if withPost {
                    return showFirstCell(by: indexPath)
                } else {
                    fallthrough
                }
            default:
                let message = arrayOfChats[indexPath.section - (withPost ? 1 : 0)].messages[indexPath.row]
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
        } else if arrayOfChats[section - (withPost ? 1 : 0)].messages.count == 0 {
            return 0.00001
        } else {
            return headerHeight
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return nil
        } else {
            if let firstMessageInSection = arrayOfChats[section - (withPost ? 1 : 0)].messages.first {
                let createdAt = firstMessageInSection.createdAt
                let sectionTitle = UILabel()
                
                if createdAt.isToday == true {
                    sectionTitle.text = R.string.localizable.todayHeaderTitle()
                } else if createdAt.isYesterday == true {
                    sectionTitle.text = R.string.localizable.yesterdayHeaderTitle()
                } else {
                    sectionTitle.text = createdAt.dateString
                }
                
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
extension CommentsController: PostCellDelegate {
    
    func reactionSelected(_ reaction: Reaction, for post: PostModel) {
        
    }
    
    func reactionRemoved(for post: PostModel) {
        
    }
    
    func openMedia(_ media: MediaDataModel) {
        if media.type == .image {
            MyPostsRouter(in: RootRouter.shared.rootNavigationController).openImage(imageUrl: media.origin)
            return
        }
        if media.type == .video {
            MyPostsRouter(in: RootRouter.shared.rootNavigationController).openVideo(videoURL: media.origin)
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
            BasicProfileRouter(in: RootRouter.shared.rootNavigationController).openPublicProfileViewController(profileId: profile.id)
        case .business:
            BusinessProfileRouter(in: RootRouter.shared.rootNavigationController).openPublicProfileController(id: profile.id)
        }
    }
    
    func followPost(_ post: PostModel) {
        
    }
    
    func showCurrentProfilePage() {
        MainScreenRouter(in: RootRouter.shared.rootNavigationController).openMyProfile()
    }
    
    func openDetailsScreen(post: PostModel) {}

    func openReactions(post: PostModel) {
        BottomMenuPresentationManager.present(ReactionsListViewController(post: post), from: self)
    }

    func hashtagSelected(_ hashtag: String) {
        MyPostsRouter(in: RootRouter.shared.rootNavigationController).openHashtagPage(hashtag: hashtag)
    }

    func mentionSelected(profileId: Int) {
        profileNavigationResolver.openProfile(profileId: profileId)
    }

    func mediaViewed(media: MediaDataModel) {
    }
}

// MARK: - MenuActionButtonDelegate
extension CommentsController: MenuActionButtonDelegate {
    func openMenu(post: PostModel) {
        let controller = EntityMenuController(entity: post)
        controller.onMenuSelected = { [weak self] (type, post) in
            guard let self = self else {
                return
            }
            switch type {
            case .edit:
                BasicProfileRouter(in: self.navigationController).openEditPost(post: post, delegate: self)
            case .unfollow:
                break
//                self.deleteFollowFromPost(post: post)
            case .delete:
                break
//                self.deletePost(post)
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
extension CommentsController: PostFormDelegate {
    func newPostAdded(post: PostModel) {}

    func postUpdated(post: PostModel) {
        
    }
    
    func postRemoved(post: PostModel) {}
}

// MARK: - ChatMessageSenderProtocol

extension CommentsController: ChatMessageSenderProtocol {
    func didTapSend(text: String?, attachment: ChatTextFieldView.Attachment?) {
        guard let currentProfile = ArchiveService.shared.currentProfile else {
            return
        }
        guard formIsValid() else {
            return
        }
        let currentPost = self.currentPost
        if attachment != nil {
            chatView.recordButton.isLoading = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                self.addAttachment { [weak self] (savedAttachment) in
                    self?.chatView.clear()
                    self?.sendMessage(data: ChatAttach(text: text, attachmentId: savedAttachment.id, messageId: nil, postId: currentPost.id, profileId: currentProfile.id))
                }

            }

        } else {
            chatView.recordButton.isLoading = true
            chatView.clear()
            sendMessage(data: ChatAttach(text: text, attachmentId: nil, messageId: nil, postId: currentPost.id, profileId: currentProfile.id))
        }
    }

    func didTapUpdate(messageID: Int, text: String?, attachment: ChatTextFieldView.Attachment?) {
        if attachment != nil {
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
            updatePostMessage(messageID: messageID, text: text, attachmentID: nil)
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

extension CommentsController {
    
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

extension CommentsController: PostCommentCellDelegate {
    func profileSelected(for message: ChatMessageModel) {
        guard let profile = message.profile else {
            return
        }
        if profile.id == ArchiveService.shared.currentProfile?.id {
            showCurrentProfilePage()
            return
        }
        if profile.type == .basic {
            BasicProfileRouter(in: RootRouter.shared.rootNavigationController).openPublicProfileViewController(profileId: profile.id)
        } else {
            BusinessProfileRouter(in: RootRouter.shared.rootNavigationController).openPublicProfileController(id: profile.id)
        }
    }

    func cellNeedResize(cell: BasePostCommentCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            expandedComments[indexPath] = true
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
}

extension CommentsController: ChatAttachmentDelegate {
    func mediaDidSelected(media: ChatAttachmentModel) {
        switch media.type {
        case .image:
            MyPostsRouter(in: RootRouter.shared.rootNavigationController).openImage(imageUrl: media.origin)
        case .video:
            MyPostsRouter(in: RootRouter.shared.rootNavigationController).openVideo(videoURL: media.origin)
        default:
            break
        }
    }
}

// MARK: - MediaProcessing

extension CommentsController: MediaProcessorDelegate {
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
