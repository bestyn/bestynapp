//
//  RestReactionsManager.swift
//  neighbourhood
//
//  Created by Artem Korzh on 13.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import GBKSoftRestManager

class RestReactionsManager: RestOperationsManager {

    func addReaction(postID: Int, reaction: Reaction) -> PreparedOperation<PostReactionModel> {
        let request = Request(
            url: RestURL.Reactions.postReactions(postID: postID),
            method: .post,
            withAuthorization: true,
            body: ["reaction": reaction])
        return prepare(request: request)
    }

    func reactionsList(postID: Int, reaction: Reaction?, page: Int) -> PreparedOperation<[PostReactionModel]> {
        var query: [String: Any] = [
            "expand": "profile.avatar.formatted",
            "page": page
        ]
        if let reaction = reaction {
            query["reaction"] = reaction
        }
        let request = Request(
            url: RestURL.Reactions.postReactions(postID: postID),
            method: .get,
            query: query,
            withAuthorization: true)
        return prepare(request: request)
    }

    func removeReaction(postID: Int) -> PreparedOperation<Empty> {
        let request = Request(
            url: RestURL.Reactions.postReactions(postID: postID),
            method: .delete,
            withAuthorization: true)
        return prepare(request: request)
    }
}
