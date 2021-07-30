//
//  ChatListCell.swift
//  neighbourhood
//
//  Created by Dioksa on 31.03.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

final class ChatListCell: UITableViewCell {
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var messageLabel: UILabel!
    @IBOutlet private weak var unreadMessagesView: UIView!
    @IBOutlet private weak var unreadMessagesCountLabel: UILabel!
    @IBOutlet private weak var messageDateLabel: UILabel!
    @IBOutlet private weak var attachmentIconImageView: UIImageView!
    @IBOutlet private weak var avatarView: MediumAvatarView!
    @IBOutlet private weak var onlineIndicator: UIView!
    @IBOutlet private weak var readMarkImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
    }
    
    public func updateCell(with chat: PrivateChatListModel) {
        nameLabel.text = chat.profile?.fullName ?? "Deleted"
        
        defineLastMessageTitle(chat.lastMessage)
        defineCountLabelText(chat.unreadTotal)
        avatarView.isBusiness = chat.profile?.type == .business
        avatarView.updateWith(imageURL: chat.profile?.avatar?.formatted?.small, fullName: chat.profile?.fullName ?? "Deleted")
        configureMessageDate(for: chat.lastMessage)
        updateReadMark(message: chat.lastMessage)

        unreadMessagesView.isHidden = chat.unreadTotal == .zero
        attachmentIconImageView.isHidden = ![.image, .other, .video].contains(chat.lastMessage.attachment?.type)
        onlineIndicator.isHidden =  !(chat.profile?.isOnline ?? false)
    }
    
    // MARK: - Private
    private func configureMessageDate(for lastMessage: PrivateChatMessageModel) {
        if lastMessage.createdAt.isToday {
            messageDateLabel.text = lastMessage.createdAt.timeString
        } else if lastMessage.createdAt.isCurrentYear {
            messageDateLabel.text = lastMessage.createdAt.dateString
        } else {
            messageDateLabel.text = lastMessage.createdAt.fullDateString
        }
    }

    private func defineLastMessageTitle(_ lastMessage: PrivateChatMessageModel) {
        if lastMessage.attachment?.type == .voice {
            messageLabel.text = R.string.localizable.voiceMessageTitle()
        } else if lastMessage.attachment == nil {
            var textToShow = lastMessage.text
            
            while let mention = textToShow.linksRanges(types: [.rawMentions]).sorted(by: {$0.range.lowerBound < $1.range.lowerBound}).first {
                var link = mention.link
                link.remove(at: link.index(link.endIndex, offsetBy: -1))
                link.remove(at: link.startIndex)
                let values = link.split(separator: "|")
                if let id = Int(values.last!) {
                    let name = "@\(link.replacingOccurrences(of: "|\(id)", with: ""))"
                    textToShow = (textToShow as NSString).replacingCharacters(in: mention.range, with: name)
                }
            }
            messageLabel.text = textToShow
        } else {
            messageLabel.text = lastMessage.attachment?.originName
        } 
    }

    private func updateReadMark(message: PrivateChatMessageModel) {
        readMarkImageView.isHidden = !message.isMy
        readMarkImageView.image = message.isRead ? R.image.chat_list_sent_read_icon() : R.image.chat_list_sent_unread_icon()
    }
    
    private func defineCountLabelText(_ unreadMessages: Int) {
        unreadMessagesCountLabel.text = unreadMessages.counter(max: 99)
    }
}
