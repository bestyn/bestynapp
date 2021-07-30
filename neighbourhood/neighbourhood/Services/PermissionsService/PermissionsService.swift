//
//  PermissionsService.swift
//  neighbourhood
//
//  Created by Artem Korzh on 04.01.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import Foundation
import AVFoundation
import Photos
import CoreLocation


enum PermissionType {
    case gallery
    case video
    case camera
    case audio
    case location
}

struct PermissionsService {

    struct PermissionsResult {
        let granted: [PermissionType]
        let restricted: [PermissionType]

        var allGranted: Bool {
            restricted.count == 0
        }
    }

    public var shouldAskPermissions = true

    func checkPermission(types: [PermissionType], completion: @escaping (PermissionsResult) -> Void) {
        var grantedPermissions: [PermissionType] = []
        var restrictedPermissions: [PermissionType] = []
        let group = DispatchGroup()
        for type in types {
            group.enter()
            askPermission(type: type) { (granted) in
                granted ? grantedPermissions.append(type) : restrictedPermissions.append(type)
                group.leave()
            }
        }
        group.notify(queue: .main) {
            completion(.init(granted: grantedPermissions, restricted: restrictedPermissions))
        }
    }

    private func askPermission(type: PermissionType, completion: @escaping (Bool) -> Void) {
        switch type {
        case .gallery:
            galleryPermissions(completion: completion)
        default:
            break
        }
    }
}

extension PermissionsService {
    private func galleryPermissions(completion: @escaping (Bool) -> Void) {
        func checkStatus(_ status: PHAuthorizationStatus) {
            switch status {
            case .authorized, .limited:
                completion(true)
            case .denied, .restricted:
                completion(false)
            case .notDetermined:
                if shouldAskPermissions {
                    PHPhotoLibrary.requestAuthorization(checkStatus(_:))
                } else {
                    completion(false)
                }
            @unknown default:
                completion(false)
            }
        }

        let authStatus: PHAuthorizationStatus = {
            if #available(iOS 14, *) {
                return PHPhotoLibrary.authorizationStatus(for: .readWrite)
            } else {
                return PHPhotoLibrary.authorizationStatus()
            }
        }()
        checkStatus(authStatus)
    }
}
