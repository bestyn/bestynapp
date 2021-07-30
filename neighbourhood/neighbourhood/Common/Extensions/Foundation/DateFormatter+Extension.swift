//
//  DateFormatter+Extension.swift
//  neighbourhood
//
//  Created by Dioksa on 11.05.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

extension DateFormatter {
    private static func formatter(of format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter
    }
    
    static var dateTimeFormatter: DateFormatter {
        formatter(of: GlobalConstants.DateFormats.dateTime)
    }

    static var fullDateTimeFormatter: DateFormatter {
        formatter(of: GlobalConstants.DateFormats.fullDateTime)
    }

    static var timeFormatter: DateFormatter {
        formatter(of: GlobalConstants.DateFormats.time)
    }

    static var dateFormatter: DateFormatter {
        formatter(of: GlobalConstants.DateFormats.date)
    }

    static var fullDateFormatter: DateFormatter {
        formatter(of: GlobalConstants.DateFormats.fullDate)
    }
}
