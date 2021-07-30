//
//  RestPrivateChatManager.swift
//  neighbourhood
//
//  Created by Dioksa on 16.07.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import UIKit
import GBKSoftRestManager

final class RestPrivateChatManager: RestOperationsManager {

    // MARK: - Chat list actions

    func getChatList(search: String? = nil, page: Int) -> PreparedOperation<[PrivateChatListModel]> {
        var query: [String: Any] = [
            "expand": "lastMessage.attachment.formatted, profile.avatar.formatted, profile.isOnline, firstUnreadMessage",
            "page": page
        ]
        if let search = search {
            query["search"] = search
        }
        
        let request = Request(
            url: RestURL.PrivateChats.getConversationList,
            method: .get,
            query: query,
            withAuthorization: true)
        
        return prepare(request: request)
    }

    func deleteChat(chatID: Int) -> PreparedOperation<Empty> {
        let request = Request(
            url: RestURL.PrivateChats.archiveChat(chatID),
            method: .patch,
            withAuthorization: true)

        return prepare(request: request)
    }

    func getConversationBy(publicProfileId: Int) -> PreparedOperation<PrivateChatListModel> {
        let query: [String: Any] = [
            "collocutorId": publicProfileId,
            "expand": "profile, attachment.formatted, senderProfile, recipientProfile, lastMessage.attachment.formatted, profile.avatar.formatted, profile.isOnline"]

        let request = Request(
            url: RestURL.PrivateChats.getConversationId,
            method: .get,
            query: query,
            withAuthorization: true)

        return prepare(request: request)
    }

    // MARK: - Message actions

    func sendMessage(data: SendMessageData) -> PreparedOperation<PrivateChatMessageModel> {
        let request = Request(
            url: RestURL.PrivateChats.createMessage,
            method: .post,
            withAuthorization: true,
            body: data)

        return prepare(request: request)
    }

    func updateMessage(data: SendMessageData, messageId: Int) -> PreparedOperation<PrivateChatMessageModel> {
        let request = Request(
            url: RestURL.PrivateChats.chatAction(messageId),
            method: .patch,
            query: ["expand": "attachment.formatted"],
            withAuthorization: true,
            body: data)

        return prepare(request: request)
    }
    
    func getMessages(conversationId: Int, lastId: Int? = nil) -> PreparedOperation<[PrivateChatMessageModel]> {
        var query: [String: Any] = [
            "expand": "attachment.formatted, senderProfile, recipientProfile,attachment.additional"
        ]
        
        if let lastId = lastId {
            query["lastId"] = lastId
        }
        
        let request = Request(
            url: RestURL.PrivateChats.getConversation(by: conversationId),
            method: .get,
            query: query,
            withAuthorization: true)
        
        return prepare(request: request)
    }
    
    func deleteMessage(id: Int) -> PreparedOperation<Empty> {
        let request = Request(
            url: RestURL.PrivateChats.chatAction(id),
            method: .delete,
            withAuthorization: true)
        
        return prepare(request: request)
    }

    func markReadMessages(ids: [Int]) -> PreparedOperation<ExtraDataModel> {
        let request = Request(
            url: RestURL.PrivateChats.readMessages,
            method: .patch,
            withAuthorization: true,
            body: ["ids": ids])

        return prepare(request: request)
    }

    func markReadConversation(id: Int) -> PreparedOperation<ExtraDataModel> {
        let request = Request(
            url: RestURL.PrivateChats.readConversationMessages(id),
            method: .patch,
            withAuthorization: true)

        return prepare(request: request)
    }

    // MARK: - Message attachments

    func saveImageAttachments(image: UIImage) -> PreparedOperation<ChatAttachmentModel> {
        return saveAttachment(type: .image, media: .jpg(image, nil))
    }

    func saveVideoAttachment(videoURL: URL) -> PreparedOperation<ChatAttachmentModel> {
        return saveAttachment(type: .video, media: .mp4(videoURL))
    }

    func saveFileAttachment(fileURL: URL) -> PreparedOperation<ChatAttachmentModel> {
        return saveAttachment(type: .other, media: .custom(fileURL: fileURL, contentType: fileURL.mimeType))
    }

    func saveVoiceAttachment(voiceURL: URL) -> PreparedOperation<ChatAttachmentModel> {
        return saveAttachment(type: .voice, media: .custom(fileURL: voiceURL, contentType: "audio/wav"))
    }

    private func saveAttachment(type: TypeOfAttachment, media: RequestMedia) -> PreparedOperation<ChatAttachmentModel> {

        let request = Request(
            url: RestURL.PrivateChats.addAttachment,
            method: .post,
            query: ["expand": "attachment.formatted"],
            withAuthorization: true,
            body: ["typeName": type.rawValue],
            media: ["file": media])
        
        return prepare(request: request)
    }

    func listenVoiceMessage(attachmentID: Int) -> PreparedOperation<Empty> {
        let request = Request(
            url: RestURL.PrivateChats.listemVoice(attachmentID: attachmentID),
            method: .patch,
            withAuthorization: true)
        return prepare(request: request)
    }
}
