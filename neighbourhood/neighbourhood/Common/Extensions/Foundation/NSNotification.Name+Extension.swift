//
//  NSNotification.Name+Extension.swift
//  neighbourhood
//
//  Created by Artem Korzh on 21.08.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let profileSelectorDidPressed = Notification.Name("ProfileSelectorDidPressed")
    static let profileDidChanged = Notification.Name("ProfileDidChanged")
    static let profileDidSet = Notification.Name("ProfileDidSet")
    static let tabbarUpdated = Notification.Name("TabbarUpdated")
    static let chatUnreadMessageServiceUpdateUnreadMessageNotification = Notification.Name("ChatUnreadMessageServiceUpdateUnreadMessageNotification")

    static let startPlayingVoiceMessage = Notification.Name("StartPlayingVoiceMessage")
    static let pausePlayingVoiceMessage = Notification.Name("PausePlayingVoiceMessage")
    static let stopPlayingVoiceMessage = Notification.Name("StopPlayingVoiceMessage")
    static let timerPlayingVoiceMessage = Notification.Name("TimerPlayingVoiceMessage")

    static let startSpeakingTextMessage = Notification.Name("StartSpeakingTextMessage")
    static let stopSpeakingTextMessage = Notification.Name("StopSpeakingTextMessage")

    static let restSetupComplete = Notification.Name("RestSetupComplete")

    static let storiesMuted = Notification.Name("StoriesMuted")
    static let postCommentsUpdated = Notification.Name("PostCommentsUpdated")
    static let postUpdated = Notification.Name("PostUpdated")
    static let postCreated = Notification.Name("PostCreated")
    static let postRemoved = Notification.Name("PostRemoved")

    static let audioTrackPaused = Notification.Name("AudioTrackPaused")
    static let audioTrackPlaying = Notification.Name("AudioTrackPlaying")
    static let audioTrackProgress = Notification.Name("AudioTrackProgress")
}
