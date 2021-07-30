//
//  Reportable+Extension.swift
//  neighbourhood
//
//  Created by Artem Korzh on 09.11.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

extension PostModel: Reportable {
    var reportableID: Int { id }
    var reportableType: ReportEntityType { .post }
    // TODO: - add other option
    var reportReasons: [ReportReason] { [.inappropriate, .spam] }
    var reportEntityName: String {
        if type == .media {
            return R.string.localizable.mediaEntity()
        }
        return R.string.localizable.postEntity()
    }
}

extension PublicProfileModel: Reportable {
    var reportableID: Int { id }
    var reportableType: ReportEntityType { .profile }
    var reportReasons: [ReportReason] {
        // TODO: - add other option
        [.fake, .privacy, .vandalism, .inappropriate, .spam]
    }
    var reportEntityName: String { R.string.localizable.userEntity() }
}

extension BusinessProfile: Reportable {
    var reportableID: Int { id }
    var reportableType: ReportEntityType { .profile }
    var reportReasons: [ReportReason] {
        // TODO: - add other option
        [.fake, .privacy, .vandalism, .inappropriate, .spam]
    }
    var reportEntityName: String { R.string.localizable.userEntity() }
}

extension AudioTrackModel: Reportable {
    var reportableID: Int { id }
    var reportableType: ReportEntityType { .audio }
    var reportReasons: [ReportReason] {
        [.inappropriate, .plagiarism, .other]
    }
    var reportEntityName: String { R.string.localizable.audioEntity() }
}

extension PostProfileModel: Reportable {
    var reportableID: Int { id }
    var reportableType: ReportEntityType { .profile }
    var reportReasons: [ReportReason] {
        // TODO: - add other option
        [.fake, .privacy, .vandalism, .inappropriate, .spam]
    }
    var reportEntityName: String { R.string.localizable.userEntity() }
}
