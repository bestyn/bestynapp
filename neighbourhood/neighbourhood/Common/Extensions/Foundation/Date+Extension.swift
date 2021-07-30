//
//  Date+Extension.swift
//  neighbourhood
//
//  Created by Dioksa on 28.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

extension Date {
    init(seconds: Int) {
        self = Date(timeIntervalSince1970: TimeInterval(seconds))
    }

    var withoutSeconds: Date {
        let components = Calendar.current.dateComponents([.year,.month,.day,.hour,.minute], from: self)
        return Calendar.current.date(from: components) ?? self
    }
    
    public var isToday: Bool {
        return NSCalendar.current.isDateInToday(self)
    }
    
    public var isYesterday: Bool {
        return NSCalendar.current.isDateInYesterday(self)
    }
    
    public var midnight: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    public func isDateTimeEqual(_ date: Date) -> Bool {
        return Calendar.current.isDate(self, equalTo: date, toGranularity: .minute)
    }
    
    public func isDateEqual(_ date: Date) -> Bool {
        return Calendar.current.isDate(self, equalTo: date, toGranularity: .day)
    }
    
    public var timeString: String {
        DateFormatter.timeFormatter.string(from: self)
    }
    
    public var dateString: String {
        DateFormatter.dateFormatter.string(from: self)
    }
    
    public var fullDateString: String {
        DateFormatter.fullDateFormatter.string(from: self)
    }

    public var dateTimeString: String {
        return DateFormatter.dateTimeFormatter.string(from: self)
    }

    public var fullDateTimeString: String {
        return DateFormatter.fullDateTimeFormatter.string(from: self)
    }

    
    public var isCurrentYear: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .year)
    }

    var postDateTimeString: String {
        if self.isCurrentYear {
            return "\(self.dateString) at \(self.timeString)"
        } else {
            return "\(self.fullDateString) at \(self.timeString)"
        }
    }

    var eventDateTimeString: String {
        isCurrentYear ? dateTimeString : fullDateTimeString
    }
}
