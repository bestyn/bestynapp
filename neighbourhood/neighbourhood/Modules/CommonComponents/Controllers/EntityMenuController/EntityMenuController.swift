//
//  EntityMenuController.swift
//  neighbourhood
//
//  Created by Artem Korzh on 23.10.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

enum ActionSheetButtonType {
    case copy, edit, unfollow, report, delete, setAsAvatar, openChat, createDuet, downloadVideo, removeFollower

    var defaultTitle: String {
        switch self {
        case .copy:
            return R.string.localizable.copyDescription()
        case .edit:
            return R.string.localizable.editButtonTitle()
        case .unfollow:
            return R.string.localizable.unfollowButtonTitle()
        case .report:
            return R.string.localizable.reportEntityOption(R.string.localizable.postEntity())
        case .delete:
            return R.string.localizable.deleteButtonTitle()
        case .setAsAvatar:
            return R.string.localizable.setAsAvatar()
        case .openChat:
            return R.string.localizable.openChatWith("")
        case .createDuet:
            return R.string.localizable.createDuet()
        case .downloadVideo:
            return R.string.localizable.downloadVideo()
        case .removeFollower:
            return "Remove follower"
        }
    }
}

protocol ActionSheetButtonProtocol: class {
    associatedtype Entity: MenuSupporting
    func buttonTapped(type: ActionSheetButtonType, for entity: Entity)
}

protocol MenuSupporting {
    var menuActions: [ActionSheetButtonType] { get }
    var customMenuTitles: [ActionSheetButtonType: String] { get }
}

class EntityMenuController<Entity: MenuSupporting> {

    private let entity: Entity
    var onMenuSelected: ((ActionSheetButtonType, Entity) -> Void)?

    init(entity: Entity) {
        self.entity = entity
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var alertController: UIAlertController {

        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.view.tintColor = R.color.secondaryBlack()
        let onMenuSelected = self.onMenuSelected
        let entity = self.entity

        entity.menuActions.forEach {(action) in
            alert.addAction(UIAlertAction(title: self.entity.customMenuTitles[action] ?? action.defaultTitle, style: .default, handler: { (_) in
                onMenuSelected?(action, entity)
            }))
        }

        alert.addAction(UIAlertAction(title: R.string.localizable.cancelTitle(), style: .cancel, handler: { (_) in }))
        return alert
    }
}
