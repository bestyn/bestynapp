//
//  UnreadMessageModel.swift
//  neighbourhood
//
//  Created by Andrii Zakhliupanyi on 13.08.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

struct UnreadMessageModel: Codable {
    let profileId: Int
    var hasUnreadMessages: Bool
    
    init(profileId: Int, hasUnreadMessages: Bool) {
        self.profileId = profileId
        self.hasUnreadMessages = hasUnreadMessages
    }
    
    init?(data: [AnyHashable : Any]?) {
        guard let data = data else {
            return nil
        }
        do {
            let json = try JSONSerialization.data(withJSONObject: data)
            let decoder = JSONDecoder()
            self = try decoder.decode(UnreadMessageModel.self, from: json)
        } catch {
            return nil
        }
    }
}
