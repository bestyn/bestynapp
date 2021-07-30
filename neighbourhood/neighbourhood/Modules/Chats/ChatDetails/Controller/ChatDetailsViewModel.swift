//
//  ChatDetailsViewModel.swift
//  neighbourhood
//
//  Created by Artem Korzh on 03.11.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import GBKSoftRestManager

class ChatDetailsViewModel {

    struct MessageGroup {
        let day: Date
        var messages: [ChatMessageDisplayable]
    }

    private var messages: [PrivateChatMessageModel] = [] {
        didSet {
            updateGroupedMessages()
        }
    }
    @Observable private(set) var messageGroups: [MessageGroup] = []
    @Observable private(set) var isLoading: Bool = true
    @Observable private(set) var isSending: Bool = false
    @Observable private(set) var lastError: Error?
    @Observable private(set) var editingMessage: PrivateChatMessageModel?
    @Observable private(set) var selectedAttachment: AttachmentData?
    @Observable private(set) var chat: PrivateChatListModel!
    @Observable private(set) var opponent: ChatProfile!

    private var isTypingTimer: Timer?
    private var unreadIndecies: (group: Int, message: Int)?
    private var unreadIndiciesDefined = false
    private var allMessagesLoad = false

    private lazy var chatManager: RestPrivateChatManager = {
        let manager: RestPrivateChatManager = RestService.shared.createOperationsManager(from: self)
        manager.assignErrorHandler { [weak self] (error) in
            self?.lastError = error
            self?.lastError = nil
        }
        return manager
    }()

    init(opponent: ChatProfile) {
        self.opponent = opponent
        self.restGetChatByOpponent(opponentID: opponent.id)
    }

    init(chat: PrivateChatListModel) {
        self.chat = chat
        opponent = chat.profile
        self.setupRealtimeListeners()
        self.restFetchMessages(conversationID: chat.id, lastMessageID: nil)
    }
}

// MARK: - Public methods

extension ChatDetailsViewModel {
    public func sendMessage(text: String?, attachment: AttachmentData?) {
        guard let attachment = attachment else {
            let data = SendMessageData(text: text, recipientProfileId: opponent.id, attachmentId: nil)
            restSendMessage(data: data)
            return
        }

        restUploadAttachment(attachment: attachment) { [weak self] (savedAttachment) in
            guard let self = self else {
                return
            }
            let data = SendMessageData(text: text, recipientProfileId: self.opponent.id, attachmentId: savedAttachment.id)
            self.restSendMessage(data: data)
        }
    }

    public func updateMessage(messageID: Int, text: String?, attachment: AttachmentData?) {
        guard let attachment = attachment else {
            let data = SendMessageData(text: text, recipientProfileId: opponent.id, attachmentId: nil)
            restUpdateMessage(messageID: messageID, data: data)
            return
        }

        restUploadAttachment(attachment: attachment) { [weak self] (savedAttachment) in
            guard let self = self else {
                return
            }
            let data = SendMessageData(text: text, recipientProfileId: self.opponent.id, attachmentId: savedAttachment.id)
            self.restUpdateMessage(messageID: messageID, data: data)
        }
    }

    public func deleteMessage(message: PrivateChatMessageModel) {
        restDeleteMessage(messageID: message.id)
    }

    public func readMessages(messages: [PrivateChatMessageModel]) {
        let ids = messages
            .filter({!$0.isRead && $0.senderProfileId != ArchiveService.shared.currentProfile?.id})
            .map({$0.id})
        if ids.count > 0 {
            restReadMessages(messageIDs: ids)
        }
    }

    public func loadOlderMessages() {
        if isLoading {
            return
        }
        if allMessagesLoad {
            return
        }
        if chat == nil {
            return
        }
        let lastID = messages.first?.id
        restFetchMessages(conversationID: chat.id, lastMessageID: lastID)
    }

    func selectAttachment(_ attachment: AttachmentData) {
        selectedAttachment = attachment
    }

    func removeSelectedAttachment() {
        selectedAttachment = nil
    }

    func beginEdit(message: PrivateChatMessageModel) {
        editingMessage = message
    }

    func sendTyping(_ isTyping: Bool) {
        guard let currentProfile = ArchiveService.shared.currentProfile else {
            return
        }
        let messageChannel = RealtimeService.Channel.privateMessages(
            selfID: currentProfile.id,
            opponentID: opponent.id)
        let message = RealtimePrivateChatTypingModel(data: TypingModel(isTyping: isTyping, profileId: currentProfile.id))
        RealtimeService.shared.send(channel: messageChannel, message: message)
        if isTyping {
            self.isTypingTimer?.invalidate()
            self.isTypingTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { (_) in
                self.sendTyping(false)
            })
        } else {
            self.isTypingTimer?.invalidate()
        }
    }

    func listenVoice(message: PrivateChatMessageModel) {
        if !message.isMy,
           let attachment = message.attachment,
           attachment.type == .voice,
           attachment.additional?.listened != true {
            restListenVoice(attachment: attachment)
        }
    }
}

// MARK: - Private methods

extension ChatDetailsViewModel {
    private func updateGroupedMessages() {
        if messages.isEmpty {
            messageGroups = []
            return
        }

        let groups: [Date: [PrivateChatMessageModel]] = .init(
            grouping: messages.sorted(by: { $1.createdAt > $0.createdAt }),
            by: { $0.createdAt.midnight })
        var completeGroups = groups
            .map({ MessageGroup(day: $0, messages: $1.reversed())})
            .sorted(by: { $0.day > $1.day })
        if !unreadIndiciesDefined {
            unreadIndiciesDefined = true
            groupLoop: for (groupIndex, group) in completeGroups.enumerated() {
                for (messageIndex, message) in group.messages.enumerated() {
                    guard let message = message as? PrivateChatMessageModel else {
                        continue
                    }
                    if message.senderProfileId == ArchiveService.shared.currentProfile?.id {
                        unreadIndecies = (0,0)
                        break groupLoop
                    }
                    if message.isRead {
                        unreadIndecies = (groupIndex, messageIndex)
                        break groupLoop
                    }
                }
            }
        }
        if let unreadIndecies = unreadIndecies {
            if unreadIndecies.group + unreadIndecies.message > 0 {
                completeGroups[unreadIndecies.group].messages.insert(UnreadMark(), at: unreadIndecies.message)
            }
        } else {
            completeGroups[completeGroups.count - 1].messages.append(UnreadMark())
        }
        messageGroups = completeGroups
    }

    private func setupRealtimeListeners() {
        guard let currentProfile = ArchiveService.shared.currentProfile else {
            return
        }
        let messageChannel = RealtimeService.Channel.privateMessages(
            selfID: currentProfile.id,
            opponentID: opponent.id)
        RealtimeService.shared.listen(channel: messageChannel) { [weak self] (message) in
            guard let self = self else {
                return
            }
            if let typingModel = message.model(of: RealtimePrivateChatTypingModel.self) {
                DispatchQueue.main.async {
                    self.handleTypingChanged(typingModel)
                }
                return
            }

            if let chatMessageModel = message.model(of: RealtimePrivateChatUpdateModel.self) {
                DispatchQueue.main.async {
                    self.handleMessageChanges(chatMessageModel)
                }
                return
            }
        }
    }

    private func handleTypingChanged(_ typingModel: RealtimePrivateChatTypingModel) {
        if typingModel.data.profileId == opponent.id {
            opponent.isTyping = typingModel.data.isTyping
        }
    }

    private func handleMessageChanges(_ updateModel: RealtimePrivateChatUpdateModel) {
        guard let currentProfile = ArchiveService.shared.currentProfile else {
            return
        }
        if let extraData = updateModel.extraData {
            ChatUnreadMessageService.shared.update(profileId: updateModel.data.recipientProfileId,
                                               hasUnreadMessages: extraData.hasUnreadMessages)
        }
        if updateModel.data.senderProfileId == currentProfile.id, updateModel.action != .update {
            return
        }
        switch updateModel.action {
        case .create:
            self.messages.insert(updateModel.data, at: 0)
        case .delete:
            self.messages = self.messages.filter({$0.id != updateModel.data.id})
        case .update:
            self.messages = self.messages.map({ (message) -> PrivateChatMessageModel in
                if message.id == updateModel.data.id {
                    return updateModel.data
                }
                return message
            })
        }
    }
}

// MARK: - REST requests

extension ChatDetailsViewModel {
    private func restSendMessage(data: SendMessageData) {
        chatManager.sendMessage(data: data)
            .onStateChanged({ [weak self] (state) in
                self?.isSending = state == .started
            })
            .onComplete { [weak self] (response) in
                guard let self = self else {
                    return
                }
                if let message = response.result {
                    self.messages.insert(message, at: 0)
                    if self.chat == nil {
                        self.restGetChatByOpponent(opponentID: self.opponent.id)
                    }
                }
            }.run()
    }

    private func restUpdateMessage(messageID: Int, data: SendMessageData) {
        chatManager.updateMessage(data: data, messageId: messageID)
            .onStateChanged({ [weak self] (state) in
                self?.isSending = state == .started
            })
            .onComplete { [weak self] (response) in
                guard let self = self else {
                    return
                }
                if let updatedMessage = response.result {
                    let messages = self.messages.map({ (message) -> PrivateChatMessageModel in
                        if message.id == updatedMessage.id {
                            return updatedMessage
                        }
                        return message
                    })
                    self.messages = messages
                }
            }.run()
    }

    private func restFetchMessages(conversationID: Int, lastMessageID: Int?) {
        chatManager.getMessages(conversationId: conversationID, lastId: lastMessageID)
            .onStateChanged { [weak self] (state) in
                self?.isLoading = state == .started
            }.onComplete { [weak self] (response) in
                guard let self = self else {
                    return
                }
                if var messages = response.result {
                    if messages.count == 0 {
                        self.allMessagesLoad = true
                    }
                    messages.removeAll { (newMessage) -> Bool in
                        self.messages.contains(where: {$0.id == newMessage.id})
                    }
                    self.messages.insert(contentsOf: messages, at: 0)
                }
            }.run()
    }

    private func restGetChatByOpponent(opponentID: Int) {
        chatManager.getConversationBy(publicProfileId: opponentID)
            .onError({ [weak self] (error) in
                self?.isLoading = false
                switch error {
                case .processingError(let code, _):
                    if code == 404 {
                        return
                    }
                default:
                    self?.lastError = error
                    self?.lastError = nil
                }
            })
            .onComplete { [weak self] (response) in
                if let chat = response.result {
                    self?.chat = chat
                    self?.opponent = chat.profile
                    self?.setupRealtimeListeners()
                    self?.restFetchMessages(conversationID: chat.id, lastMessageID: nil)
                }
            }.run()
    }

    private func restReadMessages(messageIDs: [Int]) {
        chatManager.markReadMessages(ids: messageIDs)
            .onComplete { [weak self] (response) in
                if let data = response.result, let currentProfile = ArchiveService.shared.currentProfile {
                ChatUnreadMessageService.shared.update(
                    profileId: currentProfile.id,
                    hasUnreadMessages: data.hasUnreadMessages)
                }
                guard let self = self else {
                    return
                }
                let messages = self.messages.map { (message) -> PrivateChatMessageModel in
                    var message = message
                    if messageIDs.contains(message.id) {
                        message.isRead = true
                    }
                    return message
                }
                self.messages = messages
            }.run()
    }

    private func restDeleteMessage(messageID: Int) {
        chatManager.deleteMessage(id: messageID)
            .onComplete { [weak self] (_) in
                guard let self = self else {
                    return
                }
                let messages = self.messages.filter({$0.id != messageID})
                self.messages = messages
            }.run()
    }

    private func restUploadAttachment(attachment: AttachmentData, completion: @escaping (ChatAttachmentModel) -> Void) {
        let operation: PreparedOperation<ChatAttachmentModel> = {
            switch attachment {
            case .storedImage(let url):
                return chatManager.saveImageAttachments(image: UIImage(contentsOfFile: url.path)!)
            case .capturedImage(let image):
                return chatManager.saveImageAttachments(image: image)
            case .video(let videoURL):
                return chatManager.saveVideoAttachment(videoURL: videoURL)
            case .voice(let voiceURL):
                return chatManager.saveVoiceAttachment(voiceURL: voiceURL)
            case .file(let fileURL):
                return chatManager.saveFileAttachment(fileURL: fileURL)
            }
        }()

        operation.onComplete { (response) in
            if let attachment = response.result {
                completion(attachment)
            }
        }.run()
    }

    private func restListenVoice(attachment: ChatAttachmentModel) {
        chatManager.listenVoiceMessage(attachmentID: attachment.id)
            .onComplete { [weak self] (response) in
                guard let self = self else {
                    return
                }
                self.messages = self.messages.map({ (message) -> PrivateChatMessageModel in
                    if message.attachment?.id == attachment.id {
                        var updatedMessage = message
                        updatedMessage.attachment?.additional = ChatAttachmentAdditionalModel(listened: true)
                        return updatedMessage
                    }
                    return message
                })
            }.run()
    }
}



protocol ChatMessageDisplayable {}

extension PrivateChatMessageModel: ChatMessageDisplayable {}

struct UnreadMark: ChatMessageDisplayable {}
