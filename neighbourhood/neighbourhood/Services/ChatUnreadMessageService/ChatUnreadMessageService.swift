//
//  ChatUnreadMessageService.swift
//  neighbourhood
//
//  Created by Andrii Zakhliupanyi on 13.08.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

class ChatUnreadMessageService {
    static let shared = ChatUnreadMessageService()
    private init() {}
    
    func update(profileId: Int?, hasUnreadMessages: Bool?) {
        guard let profileId = profileId,
            let hasUnreadMessages = hasUnreadMessages else {
            return
        }
        let unreadMessageModel = UnreadMessageModel(profileId: profileId, hasUnreadMessages: hasUnreadMessages)
        if var user = ArchiveService.shared.userModel {
            if user.profile.id == profileId {
                user.profile.hasUnreadMessages = hasUnreadMessages
            } else {
                user.businessProfiles = user.businessProfiles?.map({ (profile) -> BusinessProfile in
                    if profile.id == profileId {
                        var updatedProfile = profile
                        updatedProfile.hasUnreadMessages = hasUnreadMessages
                        return updatedProfile
                    }
                    return profile
                })
            }
            ArchiveService.shared.userModel = user
        }
        NotificationCenter.default.post(name: .chatUnreadMessageServiceUpdateUnreadMessageNotification,
                                        object: nil,
                                        userInfo: unreadMessageModel.dictionary)
    }
}
