//
//  RestURL.swift
//  neighbourhood
//
//  Created by Dioksa on 22.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import GBKSoftRestManager

enum RestURL {
    
    static let config = Endpoint("v1/config")
    
    enum User {
        static let signIn = Endpoint("v1/user/login")
        static let signUp = Endpoint("v1/user/register")
        static let verifyEmail = Endpoint("v1/emails/verify/confirm")
        static let verifyEmailAfterResend = Endpoint("v1/emails/verify/token")
        static let restorePassword = Endpoint("v1/user/recovery-password")
        static let newPassword = Endpoint("v1/user/new-password")
        static let signOut = Endpoint("v1/user/logout")
        static let refreshToken = Endpoint("v1/user/refresh")
    }
    
    enum Profile {
        static let profile = Endpoint("v1/user/current")
        static let changeProfile = Endpoint("v1/user/profile")
        static let changePassword = Endpoint("v1/user/change-password")
        static let changeEmail = Endpoint("v1/emails/change/token")
        static let confirmChangeEmail = Endpoint("v1/emails/change/confirm")
        
        static func getPublicProfile(_ profileId: Int) -> Endpoint {
            return Endpoint("v1/user/profile/\(profileId)")
        }
        
        static let getPosts = Endpoint("v1/posts")
        static let list = Endpoint("v1/profiles")

        static func follow(id: Int) -> Endpoint { Endpoint("v1/profile/\(id)/follow") }
        static func follower(id: Int) -> Endpoint { Endpoint("v1/profile/\(id)/follower") }
    }
    
    enum BusinessProfile {
        static let addBusinessProfile = Endpoint("v1/user/business-profile")
        
        static func getBusinessProfile(_ profileId: Int) -> Endpoint {
            return Endpoint("v1/user/business-profile/\(profileId)")
        }
        
        static func addImages(_ profileId: Int) -> Endpoint {
            return Endpoint("v1/user/business-profile/\(profileId)/media")
        }
        
        static func deleteImage(_ mediaId: Int) -> Endpoint {
            return Endpoint("v1/user/business-profile/media/\(mediaId)")
        }
    }
    
    enum MyPosts {
        static func createPost(type: TypeOfPost) -> Endpoint {
            switch type {
            case .general:
                return Endpoint("v1/posts/general")
            case .news:
                return Endpoint("v1/posts/news")
            case .crime:
                return Endpoint("v1/posts/crime")
            case .offer:
                return Endpoint("v1/posts/offer")
            case .event:
                return Endpoint("v1/posts/event")
            case .media:
                return Endpoint("v1/posts/media")
            case .story:
                return Endpoint("v1/posts/story")
            default:
                return Endpoint("")
            }
        }
        
        static func getPost(type: TypeOfPost, postId: Int) -> Endpoint {
            switch type {
            case .general:
                return Endpoint("v1/posts/general/\(postId)")
            case .news:
                return Endpoint("v1/posts/news/\(postId)")
            case .crime:
                return Endpoint("v1/posts/crime/\(postId)")
            case .offer:
                return Endpoint("v1/posts/offer/\(postId)")
            case .event:
                return Endpoint("v1/posts/event/\(postId)")
            case .media:
                return Endpoint("v1/posts/media/\(postId)")
            case .story:
                return Endpoint("v1/posts/story/\(postId)")
            default:
                return Endpoint("")
            }
        }
        
        static func addMedia(_ postId: Int) -> Endpoint {
            return Endpoint("v1/posts/\(postId)/media")
        }
        
        static func deleteMedia(_ mediaId: Int) -> Endpoint {
            return Endpoint("v1/posts/media/\(mediaId)")
        }
        
        static let getMyPosts = Endpoint("v1/my-posts")
        
        static func anyPost(_ postId: Int) -> Endpoint {
            return Endpoint("v1/posts/\(postId)")
        }
        
        static func likePost(_ postId: Int) -> Endpoint {
            return Endpoint("v1/post/\(postId)/like")
        }
        
        static func dislikePost(_ postId: Int) -> Endpoint {
            return Endpoint("v1/post/\(postId)/dislike")
        }
        
        static let localPosts = Endpoint("v1/all-posts")
        static let globalPosts = Endpoint("v1/posts")
        
        static func followPost(_ postId: Int) -> Endpoint {
            return Endpoint("v1/post/\(postId)/follow")
        }
        
        static func unfollowPost(_ postId: Int) -> Endpoint {
            return Endpoint("v1/post/\(postId)/unfollow")
        }

        static func mediaView(mediaId: Int) -> Endpoint {
            return Endpoint("v1/posts/media/\(mediaId)/view")
        }
    }
    
    enum MyHeighbors {
        static let getNeighbors = Endpoint("v1/my-neighbors")
    }
    
    enum Reports {
        static let report = Endpoint("v1/report")
    }
    
    enum Chats {
        static func chatAction(_ postId: Int) -> Endpoint {
            return Endpoint("v1/post/\(postId)/message")
        }
        
        static let addAttachment = Endpoint("v1/post/message/attachment")
        
        static func updateMessage(_ messageId: Int) -> Endpoint {
            return Endpoint("v1/post/message/\(messageId)")
        }
    }
    
    enum PrivateChats {
        static let createMessage = Endpoint("v1/profile-message")
        static let getConversationList = Endpoint("v1/profile-conversation")
        static let addAttachment = Endpoint("v1/profile-message-attachment")
        static let readMessages = Endpoint("v1/profile-message/read")
        static let getConversationId = Endpoint("v1/profile-conversation-by-collocutor")
        
        static func getConversation(by conversationId: Int) -> Endpoint {
            return Endpoint("v1/profile-conversation/\(conversationId)/message")
        }
        
        static func chatAction(_ messageId: Int) -> Endpoint {
            return Endpoint("v1/profile-message/\(messageId)")
        }
        
        static func readConversationMessages(_ conversationId: Int) -> Endpoint {
            return Endpoint("v1/profile-conversation/\(conversationId)/read")
        }
        static func archiveChat(_ chatID: Int) -> Endpoint { Endpoint("v1/profile-conversation/\(chatID)/archive") }
        static func listemVoice(attachmentID: Int) -> Endpoint { Endpoint("v1/profile-message-attachment/\(attachmentID)/listened") }
    }
    
    enum Centrifugo {
        static let connect = Endpoint("v1/centrifugo/sign")
        static let getTokenToPrivate = Endpoint("v1/centrifugo/auth")
    }

    enum Support {
        static func page(slug: String) -> Endpoint {
            return Endpoint("v1/pages/\(slug)")
        }
    }
    
    enum Categories {
        static let categories = Endpoint("v1/category")
    }
    
    enum News {
        static let newsFeed = Endpoint("v1/news-feed")
    }

    enum Payments {
        static let inAppPayment = Endpoint("v1/in-app-payment")
    }

    enum Reactions {
        static func postReactions(postID: Int) -> Endpoint { Endpoint("v1/post/\(postID)/reaction") }
    }

    enum Notifications {
        static let saveToken = Endpoint("v1/user/push-token")
    }

    enum Hashtags {
        static let list = Endpoint("v1/hashtag")
    }

    enum Stories {
        static let create = Endpoint("v1/posts/story")
        static func edit(id: Int) -> Endpoint { Endpoint("v1/posts/story/\(id)") }
    }

    enum AudioTracks {
        static let list = Endpoint("v1/audio")
        static func follow(trackID: Int) -> Endpoint { Endpoint("v1/audio/\(trackID)/favorite") }
    }
}
