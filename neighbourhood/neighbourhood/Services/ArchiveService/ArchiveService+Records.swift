//
//  ArchiveService+Records.swift
//  neighbourhood
//
//  Created by Dioksa on 22.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import UIKit

extension ArchiveService {
    
    enum Key {
        static let tokenModel = "TokenModel"
        static let userModel = "UserModel"
        static let appleFullName = "AppleFullName"
        static let appleUserIdentifier = "AppleUserIdentifier"
        static let configModel = "ConfigModel"
        static let onboarding = "Onboarding"
        static let currentId = "CurrentId"
        static let profileType = "ProfileType"
        static let newEmail = "NewEmail"
        static let seeContent = "SeeContent"
        static let centrifugoToken = "CentrifugoToken"
        static let backgroundImage = "ChatBackground"
        static let soundUrl = "SoundUrl"
        static let interests = "UserInterests"
        static let currentProfile = "CurrentProfile"
        static let recentSearches = "RecentSearches"
        static let notificationLater = "NotificationLater"
        static let hasPostedStories = "HasPostedStories"
        static let storiesMuted = "StoriesMuted"
        static let deviceID = "DeviceID"
        static let lastVisitedStory = "LastVisitedStory"
        static let isStorySaving = "IsStorySaving"
    }

    func clearUserRelatedData() {
        tokenModel = nil
        userModel = nil
        currentProfile = nil
    }
    
    var tokenModel: TokenModel? {
        get {
            return self.getModel(type: TokenModel.self, key: Key.tokenModel)
        }
        set {
            self.save(newValue, key: Key.tokenModel)
        }
    }
    
    var userModel: UserModel? {
        get {
            return self.getModel(type: UserModel.self, key: Key.userModel)
        }
        set {
            self.save(newValue, key: Key.userModel)
        }
    }
    
    var appleFullName: String? {
        get {
            return self.getModel(type: String.self, key: Key.appleFullName)
        }
        set {
            self.save(newValue, key: Key.appleFullName)
        }
    }
    
    var appleUserIdentifier: String? {
        get {
            return self.getModel(type: String.self, key: Key.appleUserIdentifier)
        }
        set {
            self.save(newValue, key: Key.appleUserIdentifier)
        }
    }
    
    var config: ConfigModel {
        get {
            return self.getModel(type: ConfigModel.self, key: Key.configModel) ?? ConfigModel.default
        }
        set {
            self.save(newValue, key: Key.configModel)
        }
    }

    var currentProfile: SelectorProfileModel? {
        get {
            return self.getModel(type: SelectorProfileModel.self, key: Key.currentProfile)
        }
        set {
            let oldValue = currentProfile
            self.save(newValue, key: Key.currentProfile)
            if newValue != nil, oldValue != nil {
                NotificationCenter.default.post(name: .profileDidChanged, object: nil)
            }
            if oldValue == nil, newValue != nil {
                NotificationCenter.default.post(name: .profileDidSet, object: nil)
            }
        }
    }
    
    var newEmail: String? {
        get {
            return self.getModel(type: [String].self, key: Key.newEmail)?.first
        }
        set {
            self.save([newValue], key: Key.newEmail)
        }
    }
    
    var seeBusinessContent: Bool {
        get {
            return self.getModel(type: [Bool].self, key: Key.seeContent)?.first ?? true
        }
        set {
            self.save([newValue], key: Key.seeContent)
        }
    }
    
    var centrifugoToken: String? {
        get {
            return self.getModel(type: [String].self, key: Key.centrifugoToken)?.first
        }
        set {
            self.save([newValue], key: Key.centrifugoToken)
        }
    }
    
    var image: String? {
        get {
            return self.getModel(type: [String].self, key: Key.backgroundImage)?.first
        }
        set {
            self.save([newValue], key: Key.backgroundImage)
        }
    }
    
    var url: URL? {
        get {
            return self.getModel(type: URL.self, key: Key.soundUrl)
        }
        set {
            self.save(newValue, key: Key.soundUrl)
        }
    }
    
    var interestExist: Bool {
        get {
            return self.getModel(type: [Bool].self, key: Key.interests)?.first ?? true
        }
        set {
            self.save([newValue], key: Key.interests)
        }
    }

    var recentSearches: [String] {
        get {
            return self.getModel(type: [String].self, key: Key.recentSearches) ?? []
        }
        set {
            self.save(newValue, key: Key.recentSearches)
        }
    }

    var notificationLater: Bool? {
        get {
            self.getModel(type: [Bool].self, key: Key.notificationLater)?.first
        }
        set {
            self.save([newValue], key: Key.notificationLater)
        }
    }

    var hasPostedStories: Bool {
        get {
            self.getModel(type: [Bool].self, key: Key.hasPostedStories)?.first ?? false
        }
        set {
            self.save([newValue], key: Key.hasPostedStories)
        }
    }

    var storiesMuted: Bool {
        get {
            self.getModel(type: [Bool].self, key: Key.storiesMuted)?.first ?? false
        }
        set {
            self.save([newValue], key: Key.storiesMuted)
            NotificationCenter.default.post(name: .storiesMuted, object: newValue)
        }
    }

    var customDeviceID: String? {
        get {
            self.getModel(type: [String].self, key: Key.deviceID)?.first
        }
        set {
            self.save([newValue], key: Key.deviceID)
        }
    }

    var lastVisitedStory: PostModel? {
        get {
            self.getModel(type: PostModel.self, key: Key.lastVisitedStory)
        }
        set {
            self.save(newValue, key: Key.lastVisitedStory)
        }
    }

    var isStorySaving: Bool {
        get {
            self.getModel(type: [Bool].self, key: Key.isStorySaving)?.first ?? false
        }
        set {
            self.save([newValue], key: Key.isStorySaving)
        }
    }
}
