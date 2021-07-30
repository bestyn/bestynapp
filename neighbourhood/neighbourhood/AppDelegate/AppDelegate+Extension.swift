//
//  AppDelegate+Extension.swift
//  neighbourhood
//
//  Created by Artem Korzh on 23.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import FirebaseCore
import GoogleMaps
import GooglePlaces
import AppSpectorSDK
import StoreKit
import AVFoundation

private let appSpectorId = "ios_NmZmMDA2MGItZWVjZS00NWUzLTllNGEtOGIzMDQwYzM0ZDBl"

extension AppDelegate {
    func setupApplication() {
        clearDefaults()
        Toast.configure()
        FirebaseApp.configure()
        
        if let options = FirebaseApp.app()?.options {
            GMSServices.provideAPIKey(options.apiKey!)
            GMSPlacesClient.provideAPIKey(options.apiKey!)
        }
        
        let config = AppSpectorConfig(apiKey: appSpectorId)
        AppSpector.run(with: config)

        SKPaymentQueue.default().add(IAPService.shared)
        RestService.shared.setupRestManager()
        try? AVAudioSession.sharedInstance().setCategory(.playback)
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.webpageURL?.absoluteString != nil {
            DynamicLinksService.shared.parseDynamicLink(link: userActivity.webpageURL!.absoluteString)
            return true
        } else {
            return false
        }
    }
    
    private func clearDefaults() {
        ArchiveService.shared.currentProfile = nil
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NotificationsService.shared.didReceiveDeviceToken(deviceToken)
    }

    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        NotificationsService.shared.didReceiveDeviceToken(deviceToken as Data)
    }

}
