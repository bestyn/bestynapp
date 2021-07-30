//
//  String+Extension.swift
//  neighbourhood
//
//  Created by Dioksa on 27.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//
import UIKit

extension String {
    var isAlphanumeric: Bool {
        return !isEmpty && range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil
    }
    
    func isNumber() -> Bool {
        return !isEmpty && range(of: "[^0-9]", options: .regularExpression) == nil
    }

    func isDecimal() -> Bool {
        return !isEmpty && range(of: "^[0-9]+(\\.|,)?[0-9]*$", options: .regularExpression) != nil
    }
    
    func indexAt(_ position: Int) -> String.Index {
        return self.index(startIndex, offsetBy: position)
    }
    
    var noSpaces: String {
        return self.replacingOccurrences(of: " ", with: "")
    }
    
    func capitalizingFirstLetter() -> String {
        return self.prefix(1).uppercased() + self.dropFirst()
    }
    
    func htmlAttributed(using font: UIFont, textColor: UIColor, accentColor: UIColor) -> NSAttributedString? {
        do {
            let htmlCSSString = """
            <style>
            body {
            color: #\(textColor.hexString!);
            font-weight: 400;
            font-family: \(font.familyName);
            font-size: \(font.pointSize)px;
            line-height: 21px;
            }
            
            ul {
            padding-left: 0;
            list-style: none;
            }
            
            span.bullet {
            display: inline-block;
            color: #\(accentColor.hexString!);
            font-weight: bold;
            }
            </style> \(self.replacingOccurrences(of: "<li>", with: "<li><span class=\"bullet\">•&nbsp;</span>"))
            """
            
            guard let data = htmlCSSString.data(using: String.Encoding.utf8) else {
                return nil
            }
            
            return try NSAttributedString(data: data,
                                          options: [.documentType: NSAttributedString.DocumentType.html,
                                                    .characterEncoding: String.Encoding.utf8.rawValue],
                                          documentAttributes: nil)
        } catch {
            debugPrint("error: ", error)
            return nil
        }
    }
    
    func slice(from: String, to: String) -> String? {
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
    
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count + 1))
    }

    var initials: String {
        self.components(separatedBy: " ").compactMap { $0.first?.uppercased() }.prefix(2).joined(separator: " ")
    }

    var firstInitial: String {
        self.first?.uppercased() ?? ""
    }

    var formattedPhoneNumber: String {
        let cleanPhoneNumber = self.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        let mask = GlobalConstants.Common.numberMask

        var result = ""

        var index = cleanPhoneNumber.startIndex
        for item in mask where index < cleanPhoneNumber.endIndex {
            if item == "X" {
                result.append(cleanPhoneNumber[index])
                index = cleanPhoneNumber.index(after: index)
            } else {
                result.append(item)
            }
        }
        return result
    }
}

extension String {
    enum LinkType: String {
        case hashtags
        case links
        case mentions
        case rawMentions

        var regex: NSRegularExpression? {
            let pattern: String
            switch self {
            case .hashtags:
                pattern = "#[^#\\s]{1,30}"
            case .links:
                pattern = "https?:\\/\\/(www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{1,256}\\.[a-zA-Z0-9()]{1,6}\\b([-a-zA-Z0-9()@:%_\\+.~#?&//=]*)"
            case .mentions:
                pattern = "@[^\\s]+"
            case .rawMentions:
                pattern = "\\[[^\\]\\[]+\\|\\d+\\]"
            }

            return try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        }
    }

    func linksRanges(types: [LinkType]) -> [(type: LinkType, link: String, range: NSRange)] {
        let attributedString = NSMutableAttributedString(string: self)
        let range = NSMakeRange(0, utf16.count)
        var result: [(LinkType, String, NSRange)] = []
        for type in types {
            guard let matches = (type.regex?.matches(in: self, options: [], range: range))?.reversed() else {
                continue
            }
            for match in matches {
                let range = match.range(at: 0)
                let link = attributedString.attributedSubstring(from: range)
                result.append((type, link.string, range))
            }
        }
        return result
    }
}

extension String {
    func matches(for pattern: String) -> [NSTextCheckingResult] {
        let range = NSMakeRange(0, utf16.count)
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            return regex.matches(in: self, options: [], range: range)
        } catch {
            return []
        }
    }

    func substring(in nsRange: NSRange) -> Substring? {
        guard let range = Range(nsRange, in: self) else {
            return nil
        }
        return self[range]
    }
}


extension String.UTF16View {
    func indexAt(_ position: Int) -> String.Index {
        return self.index(startIndex, offsetBy: position)
    }
}

extension String {
    var md5: String {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        let messageData = data(using:.utf8)!
        var digestData = Data(count: length)

        _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
            messageData.withUnsafeBytes { messageBytes -> UInt8 in
                if let messageBytesBaseAddress = messageBytes.baseAddress,
                   let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                    let messageLength = CC_LONG(messageData.count)
                    CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
                }
                return 0
            }
        }
        return digestData.map { String(format: "%02hhx", $0) }.joined()
    }
}
