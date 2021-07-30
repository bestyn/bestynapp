//
//  GlobalConstants.swift
//  neighbourhood
//
//  Created by Dioksa on 04.06.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import DeviceKit
import MobileCoreServices

public struct GlobalConstants {
    public struct Common {
        /// "(XXX)XXX-XXXX"
        static let numberMask = "(XXX)XXX-XXXX"
        static let currentCurrency = "USD"
        static let mapRadiusInMeters: Double = 80500.0
        
        static let docTypes: [String] = [
            "publicimport MobileCoreServices.text",
            kUTTypeJPEG as String,
            kUTTypePNG as String,
            "com.microsoft.word.doc",
            "org.openxmlformats.wordprocessingml.document",
            kUTTypeRTF as String,
            "com.microsoft.powerpoint.​ppt",
            "org.openxmlformats.presentationml.presentation",
            kUTTypePlainText as String,
            "com.microsoft.excel.xls",
            "org.openxmlformats.spreadsheetml.sheet",
            kUTTypePDF as String,
            kUTTypeMP3 as String
        ]

        static let audioTypes: [String] = [
            kUTTypeMP3 as String
        ]
        
        static let aboutAppUrl = URL(string: "https://bestyn.app/")
    }
    
    public struct Languages {
        /// "en-US"
        static let speechLanguage = "en-US"
    }

    public struct DateFormats {
        static let date = "MMM dd"
        static let fullDate = "MMM dd, yyyy"
        static let time = "h:mm a"
        static let dateTime = "MMM dd, h:mm a"
        static let fullDateTime = "MMM dd, yyyy, h:mm a"
    }
    
    public struct Limits {
        /// 367001600
        static let videoFileLimit = 367001600
    }
    
    public struct Dimensions {
        static let spaceForAttachment: CGFloat = 40.0
        static let oneRowHeight: CGFloat = 19.5
        static let twoRowsHeight: CGFloat = 60.0
        static let messageViewRadius: CGFloat = 16.0
        
        public static func defineChatViewHeight() -> CGFloat {
            if Device.current.isBeforeIphoneX {
                return 68.0
            } else if Device.current.isIphoneXAndAfter {
                return 98.0
            } else {
                return 98.0
            }
        }
        
       public static func defineEditedChatViewHeight() -> CGFloat {
            if Device.current.isBeforeIphoneX {
                return 100.0
            } else if Device.current.isIphoneXAndAfter {
                return 140.0
            } else {
                return 140.0
            }
        }
        
        public static func defineAdditionalSpaceHeight() -> CGFloat {
            if Device.current.isBeforeIphoneX {
                return 0.0
            } else if Device.current.isIphoneXAndAfter {
                return 25.0
            } else {
                return 15
            }
        }
    }
}
