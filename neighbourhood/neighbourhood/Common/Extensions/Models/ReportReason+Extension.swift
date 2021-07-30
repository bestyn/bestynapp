//
//  ReportReason+Extension.swift
//  neighbourhood
//
//  Created by Artem Korzh on 09.11.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

extension ReportReason {

    var title: String {
        switch self {
        case .fake:
            return R.string.localizable.reportReasonFakeProfile()
        case .privacy:
            return R.string.localizable.reportReasonPrivacy()
        case .vandalism:
            return R.string.localizable.reportReasonVandalism()
        case .inappropriate:
            return R.string.localizable.reportReasonInnapropriate()
        case .spam:
            return R.string.localizable.reportReasonSpam()
        case .other:
            return R.string.localizable.reportReasonOther()
        case .plagiarism:
            return R.string.localizable.plagiarism()
        }
    }
}
