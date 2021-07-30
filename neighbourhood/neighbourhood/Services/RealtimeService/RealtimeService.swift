//
//  RealtimeService.swift
//  neighbourhood
//
//  Created by Dioksa on 13.07.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import SwiftCentrifuge

struct RealtimeMessageModel {
    let data: Data

    func model<T: Decodable>(of type: T.Type) -> T? {
        let jsonDecoder = JSONDecoder()
        do {
            let model = try jsonDecoder.decode(type, from: data)
            return model
        } catch {
            print(error)
            return nil
        }
    }
}

typealias RealtimeHandler = (RealtimeMessageModel) -> Void

class RealtimeService {

    enum Channel {
        static func userNotifications(userID: Int) -> String { "usersMessage#\(userID)" }
        static func postComments(postID: Int) -> String { "$postMessage_\(postID)" }
        static func privateMessages(selfID: Int, opponentID: Int) -> String {
            let ids = [selfID, opponentID].sorted()
            return "$profilesMessage_\(ids[0]),\(ids[1])"
        }
    }

    static let shared = RealtimeService()

    private lazy var centrifugoOM: CentrifugoOperationsManager = {
        let manager = RestService.shared.createOperationsManager(from: self, type: CentrifugoOperationsManager.self)
        manager.assignErrorHandler { (error) in
            print(error.localizedDescription)
        }
        return manager
    }()

    private var listeners: [String: [RealtimeHandler]] = [:]
    private var client: CentrifugeClient?
    private var connected = false

    public func centrifugoAuth(client: String, channel: String, completion: @escaping () -> ()) {
        centrifugoOM.connectionAuth(CentrifugoAuthModel(client: client, channel: channel))
            .onComplete { (result) in
                completion()
            } .run()
    }
    
    public func listen(channel: String, handler: @escaping RealtimeHandler) {
        if listeners[channel] == nil {
            listeners[channel] = []
            if client != nil {
                listenChannel(channel)
            }
        }
        listeners[channel]?.append(handler)

        if client == nil {
            fetchConnectionData()
            return
        }
    }

    public func send(channel: String, message: Encodable) {
        if let data = message.json {
            client?.publish(channel: channel, data: data, completion: { (error) in
                print(error)
            })
        }
    }
    
    private func fetchConnectionData() {
        centrifugoOM.connectionToken()
            .onComplete { [weak self] (response) in
                guard let self = self else {
                    return
                }
                guard let token = response.result?.token, let url = URL(string: Configuration.centrifugoUrl) else {
                        print("Failed to fetch connection data")
                        return
                }
                ArchiveService.shared.centrifugoToken = token
                self.connectToCentrifugo(url: url, token: token)
        }.run()
    }

    private func connectToCentrifugo(url: URL, token: String) {
        var config = CentrifugeClientConfig()
        config.debug = true
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return
        }
        components.queryItems = [URLQueryItem(name: "format", value: "protobuf")]
        let client = CentrifugeClient(url: components.url!.absoluteString, config: config, delegate: self)
        client.setToken(token)
        self.client = client
        self.client?.connect()
    }

    private func setupListeners() {
        for channel in listeners.keys {
            listenChannel(channel)
        }
    }

    private func listenChannel(_ channel: String) {
        do {
            let subscription = try client?.newSubscription(channel: channel, delegate: self)
            subscription?.subscribe()
        } catch {
            print(error.localizedDescription)
        }
    }

}

// MARK: - CentrifugeClientDelegate
extension RealtimeService: CentrifugeClientDelegate {
    func onConnect(_ client: CentrifugeClient, _ event: CentrifugeConnectEvent) {
        connected = true
        setupListeners()
    }
}

// MARK: - CentrifugeSubscriptionDelegate
extension RealtimeService: CentrifugeSubscriptionDelegate {
    func onMessage(_ client: CentrifugeClient, _ event: CentrifugeMessageEvent) {
        print(String(data: event.data, encoding: .utf8))
    }
    func onDisconnect(_ client: CentrifugeClient, _ event: CentrifugeDisconnectEvent) {
        print("Disconnect", event)
    }

    func onPublish(_ sub: CentrifugeSubscription, _ event: CentrifugePublishEvent) {
        guard let listeners = listeners[sub.channel] else {
            return
        }

        listeners.forEach { (listener) in
            let message = RealtimeMessageModel(data: event.data)
            listener(message)
        }
    }

    func onSubscribeError(_ sub: CentrifugeSubscription, _ event: CentrifugeSubscribeErrorEvent) {
        print(event.message)
    }

    func onSubscribeSuccess(_ sub: CentrifugeSubscription, _ event: CentrifugeSubscribeSuccessEvent) {
        print("SUBSCRIBED TO", sub.channel)
    }

    func onUnsubscribe(_ sub: CentrifugeSubscription, _ event: CentrifugeUnsubscribeEvent) {
        print("UNSUBSCRIBED FROM", sub.channel)
    }

    func onPrivateSub(_ client: CentrifugeClient, _ event: CentrifugePrivateSubEvent, completion: @escaping (String) -> ()) {
        let data = CentrifugoAuthModel(client: event.client, channel: event.channel)
        centrifugoOM.connectionAuth(data)
            .onComplete { (response) in
                if let token = response.result {
                    completion(token.token)
                }
        }.run()
    }
}
