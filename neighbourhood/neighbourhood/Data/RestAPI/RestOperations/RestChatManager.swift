//
//  RestChatManager.swift
//  neighbourhood
//
//  Created by Dioksa on 03.07.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import UIKit
import GBKSoftRestManager

final class RestChatManager: RestOperationsManager {
    func getChatMessages(postId: Int, lastId: Int? = nil) -> PreparedOperation<[ChatMessageModel]> {
        var query: [String: Any] = ["expand": "profile, profile.avatar.formatted, attachment.formatted", "direction": "prev"]
        
        if let lastId = lastId {
            query["lastId"] = lastId
        }
        
        let request = Request(
            url: RestURL.Chats.chatAction(postId),
            method: .get,
            query: query,
            withAuthorization: true)
        
        return prepare(request: request)
    }
    
    func sendMessage(data: ChatAttach) -> PreparedOperation<ChatMessageModel> {
        let query: [String: Any] = ["expand": "profile"]

        let request = Request(
            url: RestURL.Chats.chatAction(data.postId ?? 0),
            method: .post,
            query: query,
            withAuthorization: true,
            body: data)
        
        return prepare(request: request)
    }
    
    func addAttachment(fileUrl: URL? = nil,
                       image: UIImage? = nil,
                       videoUrl: URL? = nil) -> PreparedOperation<ChatAttachmentModel> {
        
        let query: [String: Any] = ["expand": "profile"]
        
        var userMedia: [String: RequestMedia]?
        
        if let compressedImage = image?.compress(maxSizeMB: 1) {
            userMedia = ["file": .jpg(compressedImage, nil)]
        } else if let videoFile = videoUrl {
            userMedia = ["file": .mp4(videoFile)]
        } else if let file = fileUrl {
            userMedia = ["file": .custom(fileURL: file, contentType: file.mimeType)]
        }

        let request = Request(
            url: RestURL.Chats.addAttachment,
            method: .post,
            query: query,
            withAuthorization: true,
            media: userMedia)
        
        return prepare(request: request)
    }
    
    func deleteMessage(messageId: Int) -> PreparedOperation<Empty> {
        let request = Request(
            url: RestURL.Chats.updateMessage(messageId),
            method: .delete,
            withAuthorization: true)
        
        return prepare(request: request)
    }
    
    func editMessage(data: ChatAttach) -> PreparedOperation<ChatMessageModel> {
        let query: [String: Any] = ["expand": "profile, profile.avatar.formatted, attachment.formatted"]
        
        let request = Request(
            url: RestURL.Chats.updateMessage(data.messageId ?? 0),
            method: .patch,
            query: query,
            withAuthorization: true,
            body: data)
        
        return prepare(request: request)
    }
}
