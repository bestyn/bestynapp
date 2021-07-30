//
//  RestRegistrationManager.swift
//  neighbourhood
//
//  Created by Dioksa on 28.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import GBKSoftRestManager

final class RestRegistrationManager: RestOperationsManager {
    func signUp(signUpData: SignUpData) -> PreparedOperation<Empty> {
        let request = Request(
            url: RestURL.User.signUp,
            method: .post,
            body: signUpData)
        
        return prepare(request: request)
    }
    
    /// Email that was sent during sign up
    func verifyEmail(token: String) -> PreparedOperation<TokenModel> {
        let request = Request(
            url: RestURL.User.verifyEmail,
            method: .put,
            body: [
                "token": token,
                "deviceId": UIDevice.current.identifierForVendor!.uuidString
            ])
        
        return prepare(request: request)
    }
    
    /// Verify change email
    func verifyChangeEmail(token: String) -> PreparedOperation<Empty> {
        let request = Request(
            url: RestURL.Profile.confirmChangeEmail,
            method: .put,
            body: ["token": token])
        
        return prepare(request: request)
    }
    
    /// Verification email through resend link
    func sendVerificationLink(email: String) -> PreparedOperation<Empty> {
        let request = Request(
            url: RestURL.User.verifyEmailAfterResend,
            method: .post,
            body: ["email": email])
        
        return prepare(request: request)
    }
    
    func getPlaceId(latitude: Float, longitude: Float, completion: @escaping (String) -> ()) {
        let url = URL(string: "https://maps.googleapis.com/maps/api/geocode/json?latlng=\(latitude),\(longitude)&key=AIzaSyCk19AuXPIviLdXV1Acpx3p-YtDQA6d7gg")!
        
        let session = URLSession.shared
        
        let request = URLRequest(url: url)
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            
            guard error == nil else {
                return
            }
            
            guard let data = data else {
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    if let results = json["results"] as? [Any],
                        let firstAddress = results.first(where: { (($0 as! [String : Any])["types"] as? [String]) == ["street_address"] }) as? [String: Any],
                        let placeId = firstAddress["place_id"] as? String {
                        completion(placeId)
                    }
                }
            } catch let error {
                print(error.localizedDescription)
            }
        })
        
        task.resume()
    }
}
