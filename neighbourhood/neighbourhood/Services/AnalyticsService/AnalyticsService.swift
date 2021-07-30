//
//  AnalyticsService.swift
//  neighbourhood
//
//  Created by Artem Korzh on 09.09.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import FirebaseAnalytics

struct AnalyticsService {

    enum Event {
        static let confirmEmail = "confirmed_email"
        static let interestsSelected = "selected_interest"
        static let generalPostCreated = "created_general_post"
        static let newsPostCreated = "created_news_post"
        static let offerPostCreated = "created_offer_post"
        static let crimePostCreated = "created_crime_post"
        static let evemtCreated = "created_event"
        static let newsOpen = "opened_api_news"
        static let followPost = "followed_other_post"
        static let openCreatedPosts = "opened_created_posts"
        static let openFollowedPosts = "opened_followed_posts"
        static let openMapView = "opened_map_view"
        static let openChats = "opened_my_chats"
        static let addComment = "added_comment_on_post"
        static let openPlanSelector = "payment_plan_opened"
        static let sentMessage = "sent_direct_message"
        static let firstPayment = "first_payment"
        static let recurringPayment = "recurring_payment"
        static let createBusinessProfile = "created_business_profile"
    }

    static func logSignUp() {
        Analytics.logEvent(AnalyticsEventSignUp, parameters: nil)
    }

    static func logConfirmEmail() {
        Analytics.logEvent(Event.confirmEmail, parameters: nil)
    }

    static func logInterestsSelected() {
        Analytics.logEvent(Event.interestsSelected, parameters: nil)
    }

    static func logPostCreated(type: TypeOfPost) {
        switch type {
        case .general:
            Analytics.logEvent(Event.generalPostCreated, parameters: nil)
        case .news:
            Analytics.logEvent(Event.newsPostCreated, parameters: nil)
        case .offer:
            Analytics.logEvent(Event.offerPostCreated, parameters: nil)
        case .event:
            Analytics.logEvent(Event.evemtCreated, parameters: nil)
        case .crime:
            Analytics.logEvent(Event.crimePostCreated, parameters: nil)
        default:
            break
        }
    }

    static func logNewsClicked() {
        Analytics.logEvent(Event.newsOpen, parameters: nil)
    }

    static func logFollow() {
        Analytics.logEvent(Event.followPost, parameters: nil)
    }

    static func logOpenCreatedPosts() {
        Analytics.logEvent(Event.openCreatedPosts, parameters: nil)
    }

    static func logOpenFollowedPosts() {
        Analytics.logEvent(Event.openFollowedPosts, parameters: nil)
    }

    static func logOpenMapView() {
        Analytics.logEvent(Event.openMapView, parameters: nil)
    }

    static func logCommentAdded() {
        Analytics.logEvent(Event.addComment, parameters: nil)
    }

    static func logOpenChats() {
        Analytics.logEvent(Event.openChats, parameters: nil)
    }

    static func logMessageSent() {
        Analytics.logEvent(Event.sentMessage, parameters: nil)
    }

    static func logOpenPlanSelector() {
        Analytics.logEvent(Event.openPlanSelector, parameters: nil)
    }

    static func logFirstPayment() {
        Analytics.logEvent(Event.firstPayment, parameters: nil)
    }

    static func logRecurringPayment() {
        Analytics.logEvent(Event.recurringPayment, parameters: nil)
    }

    static func logBussinessProfileCreated() {
        Analytics.logEvent(Event.createBusinessProfile, parameters: nil)
    }

}
