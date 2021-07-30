//
//  Alert+Strings.swift
//  neighbourhood
//
//  Created by Dioksa on 22.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

extension Alert {

    // MARK: - Title
    enum Title {
        static let failed = "Failed"
        static let confirmEmail = "Confirm Your Email"
        static let changeEmail = "Change Email"
        static let notConfirmedEmail = "Email Not Confirmed"
        static let verifyEmail = "Verify Email"
        static let passwordChanged = "Password Changed"
        static let passwordCreated = "Password Created"
        static let passwordRecover = "Password recover"
        static let disconnectSocialNetwork = "Social Network Disconnection"
        static let removePhoto = "Remove Photo"
        static let note = "Note"
        static let orderSubmitted = "The Order is Submitted"
        static let orderUpdated = "The Order is Updated"
        static let orderCancelation = "Order Cancelation"
        static let driverProfileChanges = "Changes"
        static let signOut = "Sign Out"
        static let deleteCard = "Remove Credit Card"
        static let notificationPermission = "Notification Permission"
        static let photoLibraryPermission = "Photo Library Permission"
        static let declineOrder = "Decline Order"
        static let driverNotArrived = "Driver did not show up?"
        static let editComission = "Order Editing"
        static let deletePost = "Do you really want to delete this post?"
        static let deleteEvent = "Do you really want to delete this event?"
        static let deleteImage = "Are you sure you want to remove this image from your Album?"
        static let warning = "Warning!"
        static let noSubscriptionFound = "No subscription found"
        static let subscriptionRestored = "Active subscription found"
        static let subscriptionOnAndroid = "Subscription on another platform found"
        static func needUpdate(appName: String) -> String { "Need to Update \(appName)" }
        static let deleteChat = "Delete chat"
        static func askNotification(appName: String) -> String { "\(appName)  would like to send you notifications" }
        static let downloadStory = R.string.localizable.downloadStoryTitle()
        static let storyPermissions = "Camera and Microphone Permissions required"
        static let createStory = "Create Story"
        static let galleryPermissions = "Gallery Permissions Required"
        static let createNewStory = "Would you like to create a new story?"
    }

    // MARK: - Message

    enum Message {
        static let termsAndPrivacyRequired = "\"Terms and Conditions\" and \"Privacy policy\" must be accepted"
        static let confirmEmail = "We have sent you a link to verify your email. Please check your Inbox and Spam folders. If you haven't received a link, request the link again"
        static let changeEmail = "We have sent you a link to your email to change. Please check your Inbox and Spam folders. If you haven't received a link, request the link again"
        static let emailLinkSent = "New verification link has been sent"
        static let notConfirmedEmail = "We sent you an email but you did not confirm your email address yet. Please confirm it now or ask for another email"
        static let passwordLinkSent = "Reset password link has been sent!"
        static let passwordChanged = "Thank you, your password has been successfully changed!"
        static let resetPassword = "Password was successfully reset! Use it to log into the Bestyn application"
        static let verifyEmail = "Please note that the email address will be changed as soon as you will verify your email by following the link. "
        static let passwordCreated = "You have created your password successfully!"
        static let profileInfoUpdated = "Profile information has been successfully updated!"
        static let phoneNumberVerified = "Phone Number is verified!"
        static let phoneCodeResent = "Verification Code has been resent."
        static let phoneCodeAlreadySent = "Verification Code has been already sent"

        static let cantDisconnectSocialNetwork = "Firstly you have to connect other social network to have possibility to sign into the system or you can set the password."

        static let removePhoto = "Do you really want to remove your profile picture?"
        static let emailVerified = "Congratulations! You are now signed into the app"
        static let restorePasswordMessage = "We have sent you a link to your email to recover the password. Please check your Inbox and Spam folders. If you haven't received a link, request the link again"
        static let leaveOrderCreation = "Do you really want to leave the page? Your progress will not be saved."
        static let orderSubmitted = "Thank You! Your order has been successfully created and will be processed soon."
        static let orderUpdated = "Your order has been successfully updated and will be processed soon."
        static let orderCancelation = "Do you really want to cancel the order?"
        static let driverProfileChanges = "If you change your car or driver's license, please contact support"
        static let driverPhotoRequired = "Please upload a photo"
        static let signOut = "Do you really want to Sign Out from your Bestyn?"

        static let cardSaved = "Your card was successfully added."
        static func deleteCard(last4: String) -> String {
            return "Do you really want to remove credit card \(last4)?"
        }
        static let notificationPermission = "Please enable notification on this device, so that we can send you push-notification, according to your settings in the profile."
        static let photoLibraryPermission = "Please allow access to photo library, so that we can save media"
        static let notificationsSettingsSaved = "Notification Settings are successfully updated!"

        static let orderAssigned = "Order is successfully assigned to you!"
        static let declineOrder = "Do you really want to decline order?"
        static let orderDeclined = "Order was successfully Declined."
        static let rateUs = "You can rate us on the App Store so that you can share your review with other users."
        static let noCurrentSession = "Looks like now you don`t have orders in progress"
        static let driverNotArrived = """
It is so unfair that you have to cancel the order due to this reason. \
Please contact the driver firstly, maybe he is almost there and you don`t need to cancel the order.
"""
        static let editComission = "Kindly note that we will charge you an additional 3% from the current order value for the order update."
        static let deletedPostMessage = "In this case it will become unavailable for anyone and you won’t be able to recover it"
        static let manageSubscriptionOnAndroid = "To manage your subscription, you should use a device with Android platform on which it was purchased"
        static let subscriptionConnectedToOtherAccount = "Subscription connected to this iOS account is already linked to another user"
        static let noSubscriptionFound = "There is no active Subscription found with Bestyn for this Apple\u{00a0}ID"
        static let noSubscriptionFoundCheckAndroid = "There is no active Subscription found with Bestyn for this account Apple\u{00a0}ID on iOS platform. Check it on your Android where it was purchased."
        static let noSubscriptionFoundCheckIOS = "There is no active Subscription found with Bestyn for this account Apple\u{00a0}ID on iOS platform. Check it on your iOS where it was purchased."
        static let subscriptionRestored = "Your subscription was successfully restored"
        static func needUpdate(appName: String) -> String { "Please update \(appName), so that it could work in correct manner." }

        static let pleaseWaitResend = "Please, wait for email a little before you try again"
        static let chatBackroungChanged = R.string.localizable.chatBackgroundChanged()
        static let deleteChat = "Are you sure you want to delete this chat?"
        static func askNotification(appName: String) -> String { "Please allow \(appName) to send you push notifications. We will notify you about new chat messages and other activity." }

        static let downloadStory = R.string.localizable.downloadStoryMessage()
        static func storyPermissions(appName: String) -> String { "Please go to settings to enable Camera and Microphone so that you can record a Story on \(appName)."}

        static func objectCreated(object: String) -> String { "Your \(object) has been successfully created." }
        static func objectUpdated(object: String) -> String { "Your \(object) has been successfully updated." }
        static var deleteLastClip = "Are you sure you want to delete the last clip?"
        static let createStory = "You can post stories to share with the whole world! Stories are not limited to your neighborhood radius."
        static let cancelChanges = "Your changes will not be saved."
        static let deleteClip = "Are you sure you want to delete this clip?"
        static let deleteStoryText = "Are you sure you want to delete this text?"
        static func galleryPermissions(appName: String) -> String  {
            "Please go to settings to enable \(appName) to access your Gallery so that you can select images and videos for your Posts on Bestyn."
        }
        static let noMediaSelected = "You have not selected any media file yet. Please, pick up an image or video to continue"
        static let deleteStory = "Are you sure you want to delete this story?"
        static let storyDeleted = "Your story has been successfully deleted."
        static let recreateFromGallery = "Tap 'Yes' if you want to continue and create a new story with different media files.\nTap 'Cancel' and then the 'Adjust Story' button to add more images or videos to the current story"
        static let adjustConfirm = "The applied text will be removed from the trimmed video clips. Would you like to continue?"
        static let iCloudSync = "Please wait. Your media files are syncing with iCloud"
        static let cantAddText = "You can’t add any more text areas."
        static let audioTrackSaved = "New audio track has been successfully added."
    }

    // MARK: - ErrorMessage

    enum ErrorMessage {
        static let serverUnavailable = "Something went wrong. Please try again."
        static let maxProfileCount = "Maximum number of Business Profiles already exists."
        static let noInternetConnection = R.string.localizable.internetConnectionError()
        static let registrationFailed = ""
        static let twoPointsRequired = "Points should contain at least 2 points"
        static let flightDurationTooLong = "Flight duration must be no greater than %d minutes"
        static let flightDurationTooShort = "Flight duration must be no less than 1 minute"
        static let driversAge = "You must be older than 20 years old."
        static let audioTooLong = "Audio track must be at most 5m long."
        static let audioTooBig = "The file is too big. Its size cannot exceed 20MB."
    }

    // MARK: - Action

    enum Action {
        static let ok = "OK"
        static let cancel = "Cancel"
        static let resendLink = "Resend Link"
        static let yes = "Yes"
        static let no = "No"
        static let support = "Get Support"
        static let done = "Done"
        static let signOut = "Sign Out"
        static let logOut = "Log Out"
        static let settings = "Settings"
        static let close = "Close"
        static let submit = "Submit"
        static let `continue` = "Continue"
        static let update = "Update"
        static let later = "Later"
        static let allow = "Allow"
        static let download = "Download"
        static let openSettings = "Go to Settings"
        static let delete = "Delete"
        static let getStarted = "Get Started"

        enum CancelOrder {
            static let plansHaveChanged = "My plans changed"
            static let driverNotArrived = "Driver did not show up"
            static let cancel = "Cancel the order"
            static let waitDriver = "Wait for the driver"
        }
    }
}
