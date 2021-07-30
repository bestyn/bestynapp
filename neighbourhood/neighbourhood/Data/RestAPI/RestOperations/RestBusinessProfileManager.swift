//
//  RestBusinessProfileManager.swift
//  neighbourhood
//
//  Created by Dioksa on 13.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import UIKit
import GBKSoftRestManager

final class RestBusinessProfileManager: RestOperationsManager {
    func addProfile(data: BusinessProfileData,
                    image: UIImage?) -> PreparedOperation<BusinessProfile> {
        
        var userImage: [String: RequestMedia]?
        
        if let compressedImage = image?.compress(maxSizeMB: 1) {
            userImage = ["image": .jpg(compressedImage, nil)]
        }
        
        let query: [String: Any] = [
            "expand": "avatar.formatted, hashtags"
        ]
        
        let request = Request(
            url: RestURL.BusinessProfile.addBusinessProfile,
            method: .post,
            query: query,
            withAuthorization: true,
            body: data,
            media: userImage)
        
        return prepare(request: request)
    }
    
    func getBusinessProfiles(profileId: Int) -> PreparedOperation<BusinessProfile> {

        let query: [String: Any] = [
            "expand": "avatar.formatted,hashtags,images.formatted,isFollower,isFollowed"
        ]
        
        let request = Request(
            url: RestURL.BusinessProfile.getBusinessProfile(profileId),
            method: .get,
            query: query,
            withAuthorization: true)
        
        return prepare(request: request)
    }
    
    func updateProfile(id: Int, data: BusinessProfileData?,
                       image: UIImage?) -> PreparedOperation<BusinessProfile> {
        
        var userImage: [String: RequestMedia]?
        
        if let compressedImage = image?.compress(maxSizeMB: 1) {
            userImage = ["image": .jpg(compressedImage, nil)]
        }
        
        let query: [String: Any] = [
            "expand": "avatar.formatted, images.formatted, hashtags"
        ]
        
        let request = Request(
            url: RestURL.BusinessProfile.getBusinessProfile(id),
            method: .patch,
            query: query,
            withAuthorization: true,
            body: data,
            media: userImage)
        
        return prepare(request: request)
    }
    
    func addBusinessProfileImages(profileId: Int,
                                  image: UIImage?) -> PreparedOperation<ImageModel> {
        
        var userImage: [String: RequestMedia]?
        
        if let compressedImage = image?.compress(maxSizeMB: 1) {
            userImage = ["file": .jpg(compressedImage, nil)]
        }
        
        let request = Request(
            url: RestURL.BusinessProfile.addImages(profileId),
            method: .post,
            withAuthorization: true,
            media: userImage)
        
        return prepare(request: request)
    }
    
    func deleteBusinessProfileImages(mediaId: Int) -> PreparedOperation<ImageModel> {
        
        let request = Request(
            url: RestURL.BusinessProfile.deleteImage(mediaId),
            method: .delete,
            withAuthorization: true,
            body: ["mediaId": mediaId])
        
        return prepare(request: request)
    }
}
