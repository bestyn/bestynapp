//
//  ChatRouter.swift
//  neighbourhood
//
//  Created by Dioksa on 24.06.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import GBKRouterProtocol

struct ChatRouter: GBKRouterProtocol {
    var context: UINavigationController!
    
    func openChatBackgroundViewController() {
        let controller = ChatBackgroundViewController()
        push(controller: controller)
    }
    
    func opeChatDetailsViewController(with opponent: ChatProfile) {
        let controller = ChatDetailsViewController(opponent: opponent)
        push(controller: controller)
    }

    func opeChatDetailsViewController(chat: PrivateChatListModel) {
        let controller = ChatDetailsViewController(chat: chat)
        push(controller: controller)
    }
}
