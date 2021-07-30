//
//  ProfileNavigationResolver.swift
//  neighbourhood
//
//  Created by Artem Korzh on 18.03.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import UIKit

class ProfileNavigationResolver {

    let navigationController: UINavigationController?
    private lazy var profileManager: RestProfileManager = RestService.shared.createOperationsManager(from: self)

    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }

    func openProfile(profileId: Int) {
        if let currentProfile = ArchiveService.shared.currentProfile,
           currentProfile.id == profileId {
            MainScreenRouter(in: navigationController).openMyProfile()
            return
        }
        if let user = ArchiveService.shared.userModel {
            if user.profile.id == profileId {
                BasicProfileRouter(in: navigationController).openPublicProfileViewController(profileId: profileId)
                return
            }
            if let businessProfile = user.businessProfiles?.first(where: {$0.id == profileId}) {
                BusinessProfileRouter(in: navigationController).openPublicProfileController(id: businessProfile.id)
                return
            }
        }
        restGetProfileType(profileId: profileId)
    }

    private func restGetProfileType(profileId: Int) {
        profileManager.getBasicProfileType(profileId: profileId)
            .onError({ [weak self] (error) in
                if case .processingError(let statusCode, _) = error,
                   statusCode == 404 {
                    self?.profileManager.getBusinessProfileType(profileId: profileId)
                        .onComplete { [weak self] (_) in
                            guard let self = self else {
                                return
                            }
                            BusinessProfileRouter(in: self.navigationController).openPublicProfileController(id: profileId)
                        }.run()
                }
            })
            .onComplete { [weak self] (response) in
                guard let self = self else {
                    return
                }
                BasicProfileRouter(in: self.navigationController).openPublicProfileViewController(profileId: profileId)
            }.run()
    }
}
