//
//  ChatListViewModel.swift
//  neighbourhood
//
//  Created by Artem Korzh on 29.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

class ChatListViewModel {

    struct State {
        var loading: Bool = false
        var chats: [PrivateChatListModel] = []
        var lastError: Error?
        var currentSearch: String?
    }

    private struct FetchParams {
        let profileID: Int
        let page: Int
        let search: String?
    }

    private lazy var chatManager: RestPrivateChatManager = {
        let manager = RestService.shared.createOperationsManager(from: self, type: RestPrivateChatManager.self)
        manager.assignErrorHandler { [weak self] (error) in
            self?.state.lastError = error
            self?.state.lastError = nil
        }
        return manager
    }()

    private lazy var profileManager: RestProfileManager = RestService.shared.createOperationsManager(from: self)

    @Observable private(set) var state: State = .init()

    private var currentPage = 1
    private var lastPage = 0

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(profileChanged), name: .profileDidChanged, object: nil)
        if let user = ArchiveService.shared.userModel {
        RealtimeService.shared.listen(channel: RealtimeService.Channel.userNotifications(userID: user.id), handler: handleRealtimeMessages(_:))
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func fetchMoreChats() {
        guard lastPage > 0, currentPage <= lastPage else {
            return
        }
        guard let profileID = ArchiveService.shared.currentProfile?.id else {
            return
        }
        let params = FetchParams(profileID: profileID, page: currentPage, search: state.currentSearch)
        restFetchChats(params: params, replace: false)
    }

    func refreshChats() {
        guard let profileID = ArchiveService.shared.currentProfile?.id else {
            return
        }
        let params = FetchParams(profileID: profileID, page: 1, search: state.currentSearch)
        restFetchChats(params: params, replace: true)
    }

    func search(query: String?) {
        guard let profileID = ArchiveService.shared.currentProfile?.id else {
            return
        }
        state.currentSearch = query
        let params = FetchParams(profileID: profileID, page: 1, search: query)
        restFetchChats(params: params, replace: true)
    }

    func deleteChat(_ chat: PrivateChatListModel) {
        restDeleteChat(chat)
    }
}

// MARK: - Private functions

extension ChatListViewModel {
    @objc private func profileChanged() {
        state.currentSearch = nil
        state.chats = []
        refreshChats()
    }

    private func handleRealtimeMessages(_ message: RealtimeMessageModel) {
        guard let chatMessage = message.model(of: RealtimePrivateChatUpdateModel.self) else {
            return
        }
        let opponentID = chatMessage.data.senderProfileId == ArchiveService.shared.currentProfile?.id
            ? chatMessage.data.recipientProfileId
            : chatMessage.data.senderProfileId
        self.restRefreshSingleChat(opponentID: opponentID)
    }

    private func notifyChatRemoved() {
        Toast.show(message: R.string.localizable.chatRemoved())
    }
}

// MARK: - REST request

extension ChatListViewModel {

    private func restFetchChats(params: FetchParams, replace: Bool = false) {
        chatManager.getChatList(search: params.search, page: params.page)
            .onStateChanged({ [weak self] (state) in
                self?.state.loading = state == .started
            })
            .onComplete { [weak self] (response) in
                guard let self = self else { return }

                if let pagination = response.pagination {
                    self.currentPage = pagination.currentPage + 1
                    self.lastPage = pagination.pageCount
                }

                if var chats = response.result {
                    if replace {
                        self.state.chats = chats
                    } else {
                        chats = chats.filter({ (newChat) -> Bool in
                            return !self.state.chats.contains(where: {$0.id == newChat.id})
                        })
                        self.state.chats.append(contentsOf: chats)
                    }
                }
        }.run()
    }

    private func restRefreshSingleChat(opponentID: Int) {
        chatManager.getConversationBy(publicProfileId: opponentID)
            .onComplete { [weak self] (response) in
                guard let self = self,
                      let refreshedChat = response.result else {
                    return
                }
                var found = false
                var chats = self.state.chats.map { (chat) -> PrivateChatListModel in
                    if chat.id == refreshedChat.id {
                        found = true
                        return refreshedChat
                    }
                    return chat
                }
                if !found {
                    chats.insert(refreshedChat, at: 0)
                }
                self.state.chats = chats.sorted(by: {$0.lastMessage.createdAt > $1.lastMessage.createdAt })
            }.run()
    }

    private func restDeleteChat(_ chat: PrivateChatListModel) {
        chatManager.deleteChat(chatID: chat.id)
            .onComplete { [weak self] (_) in
                guard let self = self else {
                    return
                }
                self.notifyChatRemoved()
                self.restUpdateUser()
            }.run()
    }

    private func restUpdateUser() {
        profileManager.getUser()
            .onComplete { (response) in
                if let user = response.result {
                    ArchiveService.shared.userModel = user
                    if user.profile.id == ArchiveService.shared.currentProfile?.id {
                        ArchiveService.shared.currentProfile = user.profile.selectorProfile
                        ChatUnreadMessageService.shared.update(profileId: user.profile.id, hasUnreadMessages: user.profile.hasUnreadMessages)
                    } else if let businesProfile = user.businessProfiles?.first(where: {$0.id ==    ArchiveService.shared.currentProfile?.id}) {
                        ArchiveService.shared.currentProfile = businesProfile.selectorProfile
                        ChatUnreadMessageService.shared.update(profileId: businesProfile.id, hasUnreadMessages: businesProfile.hasUnreadMessages)
                    }
                }
            }.run()
    }
}
