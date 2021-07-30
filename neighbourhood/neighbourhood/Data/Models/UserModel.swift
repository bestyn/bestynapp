//
//  UserModel.swift
//  neighbourhood
//
//  Created by Dioksa on 30.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

struct UserModel: Codable {
    let id: Int
    let email: String?
    var profile: UserProfileModel
    var businessProfiles: [BusinessProfile]?
}


extension UserModel {
    var profiles: [SelectorProfileModel] {
        var profiles = [profile.selectorProfile]
        if let businessProfiles = self.businessProfiles?.map({$0.selectorProfile}) {
            profiles.append(contentsOf: businessProfiles)
        }
        return profiles.sorted(by: { $0.dateOfCreation! < $1.dateOfCreation! })
    }


    static func setActiveProfile(_ profile: SelectorProfileModel) {
        ArchiveService.shared.currentProfile = profile
        Toast.show(message: "\(R.string.localizable.switchedToAccount()) \(profile.fullName)")
        ChatUnreadMessageService.shared.update(profileId: profile.id, hasUnreadMessages: profile.hasUnreadMessages)
    }
}
