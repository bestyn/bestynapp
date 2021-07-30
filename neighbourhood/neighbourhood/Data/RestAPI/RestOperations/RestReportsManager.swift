//
//  RestReportsManager.swift
//  neighbourhood
//
//  Created by Dioksa on 23.06.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import GBKSoftRestManager

final class RestReportsManager: RestOperationsManager {
    func report(data: ReportData) -> PreparedOperation<Empty> {
        let request = Request(
            url: RestURL.Reports.report,
            method: .post,
            withAuthorization: true,
            body: data)
        
        return prepare(request: request)
    }
}
