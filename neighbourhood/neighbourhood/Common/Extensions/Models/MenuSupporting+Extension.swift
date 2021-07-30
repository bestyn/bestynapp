//
//  MenuSupporting+Extension.swift
//  neighbourhood
//
//  Created by Artem Korzh on 23.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

// MARK: - PostModel

extension PostModel: MenuSupporting {
    var menuActions: [ActionSheetButtonType] {
        var actions: [ActionSheetButtonType] = []
        if self.isMy, self.type != .media {
            actions.append(.edit)
        }
        if self.isMy, self.type == .media {
            actions.append(.setAsAvatar)
        }
        if self.isMy {
            actions.append(.delete)
        } else {
            actions.append(.report)
        }
        if !self.isMy, self.iFollow {
            actions.append(.unfollow)
        }
        if let description = description,
           !description.isEmpty {
            actions.append(.copy)
        }
        if !self.isMy {
            actions.append(.openChat)
        }
        
        return actions
    }

    var customMenuTitles: [ActionSheetButtonType: String] {
        var titles: [ActionSheetButtonType: String] = [
            .openChat: R.string.localizable.openChatWith(profile?.fullName ?? "")
        ]
        switch type {
        case .media:
            titles[.report] = R.string.localizable.reportEntityOption(R.string.localizable.mediaEntity())
        case .story:
            titles[.downloadVideo] = R.string.localizable.downloadVideo()
            titles[.createDuet] = R.string.localizable.createDuet()
        default:
            break
        }
        return titles
    }
}

// MARK: - PublicProfileModel

extension PublicProfileModel: MenuSupporting {
    var menuActions: [ActionSheetButtonType] {
        var actions: [ActionSheetButtonType] = [.report]
        if isFollower {
            actions.append(.removeFollower)
        }
        return actions
    }

    var customMenuTitles: [ActionSheetButtonType : String] {
        return [.report: R.string.localizable.reportEntityOption(R.string.localizable.userEntity())]
    }
}

// MARK: - BusinessProfile

extension BusinessProfile: MenuSupporting {
    var menuActions: [ActionSheetButtonType] {
        var actions: [ActionSheetButtonType] = [.report]
        if isFollower {
            actions.append(.removeFollower)
        }
        return actions
    }

    var customMenuTitles: [ActionSheetButtonType : String] {
        return [.report: R.string.localizable.reportEntityOption(R.string.localizable.userEntity())]
    }
}

// MARK: - PrivateChatMessageModel

extension PrivateChatMessageModel: MenuSupporting {

    var isMy: Bool { ArchiveService.shared.currentProfile?.id == senderProfileId }
    var isVoice: Bool { attachment?.type == .voice }

    var menuActions: [ActionSheetButtonType] {
        guard isMy else {
            return isVoice ? [] : [.copy]
        }

        return isVoice ? [.delete] : [.copy, .edit, .delete]
    }

    var customMenuTitles: [ActionSheetButtonType : String] {
        return [
            .copy: R.string.localizable.copyMessageTitle(),
            .delete: R.string.localizable.deleteMessageTitle(),
            .edit: R.string.localizable.editMessageTitle(),
        ]
    }
}

// MARK: - ChatMessageModel

extension ChatMessageModel: MenuSupporting {

    var isMy: Bool { ArchiveService.shared.currentProfile?.id == profileId }

    var menuActions: [ActionSheetButtonType] {
        return isMy ? [.copy, .edit, .delete] : [.copy]
    }

    var customMenuTitles: [ActionSheetButtonType : String] {
        return [
            .copy: R.string.localizable.copyMessageTitle(),
            .delete: R.string.localizable.deleteMessageTitle(),
            .edit: R.string.localizable.editMessageTitle(),
        ]
    }
}

// MARK: - AudioTrackModel

extension AudioTrackModel: MenuSupporting {
    var isMy: Bool { ArchiveService.shared.currentProfile?.id == profileID }

    var menuActions: [ActionSheetButtonType] {
        return [.report]
    }

    var customMenuTitles: [ActionSheetButtonType : String] {
        return [
            .report: R.string.localizable.report()
        ]
    }
}

// MARK: - StoryListModel

extension StoryListModel: MenuSupporting {
    var menuActions: [ActionSheetButtonType] {
        var actions = story.menuActions
        if story.allowedDuet {
            actions.append(.createDuet)
        }
        actions.append(.downloadVideo)
        return actions
    }

    var customMenuTitles: [ActionSheetButtonType : String] {
        story.customMenuTitles
    }
}


// MARK: - PostProfileModel

extension FollowProfileModel: MenuSupporting {
    var menuActions: [ActionSheetButtonType] {
        var actions: [ActionSheetButtonType] = [.report]
        if inFollowersList {
            actions.insert(.removeFollower, at: 0)
        }
        return actions
    }

    var customMenuTitles: [ActionSheetButtonType : String] {
        return [
            .report: "Report User"
        ]
    }


}
