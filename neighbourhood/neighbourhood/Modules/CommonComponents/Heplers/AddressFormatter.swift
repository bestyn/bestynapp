//
//  AddressFormatter.swift
//  neighbourhood
//
//  Created by Dioksa on 27.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces

struct AddressModel {
    var country: String?
    var state: String?
    var city: String?
    var street: String?
    var houseNumber: String?
    var postalCode: String?

    var addressString: String {
        let exactAddress = [houseNumber, street].compactMap({$0}).joined(separator: " ")
        return [exactAddress, city, state, country, postalCode].compactMap({$0}).joined(separator: ", ")
    }
}

final class AddressFormatter {
    
    func getAddressFromPlace(_ place: GMSPlace) -> AddressModel?  {
        guard let components = place.addressComponents  else {
            return nil
        }
        var address = AddressModel()
        
        componentsLoop: for component in components {
            for type in (component.types){
                switch(type){
                case "street_number":
                    address.houseNumber = component.name
                case "route":
                    address.street = component.name
                case "neighborhood":
                    if address.street == nil {
                        address.street = component.name
                    }
                case "political":
                    if address.street == nil {
                        address.street = component.name
                    }
                case "locality", "administrative_area_level_3":
                    address.city = component.name
                case "country":
                    address.country = component.name
                case "postal_code":
                    address.postalCode = component.name
                default:
                    continue
                }
                continue componentsLoop
            }
        }
        return address
    }

    func getAddressFromString(_ address: String, completion: @escaping (AddressModel?) -> Void) {
        let ceo: CLGeocoder = CLGeocoder()
        ceo.geocodeAddressString(address) { (placemarks, error) in
            if let error = error {
                print(error.localizedDescription)
                completion(nil)
                return
            }
            guard let placemarks = placemarks else {
                completion(nil)
                return
            }
            let address = self.checkAddress(placemarks)
            completion(address)
        }
    }
    
    func getAddressFromCoordinates(_ coordinates: CLLocationCoordinate2D, completion: @escaping (_ address: AddressModel?) -> Void) {
        let geocoder = GMSGeocoder()

        geocoder.reverseGeocodeCoordinate(coordinates) { response, error in
            if let error = error {
                print("GMSReverseGeocode Error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            guard let result = response?.results()?.first else {
                completion(nil)
                return
            }
            var address = AddressModel()
            address.street = result.thoroughfare
            address.city = result.locality
            address.state = result.administrativeArea
            address.country = result.country
            address.postalCode = result.postalCode

            completion(address)
        }
    }

    private func checkAddress(_ placemarks: [CLPlacemark]) -> AddressModel? {
        guard let placemark = placemarks.first else {
            return nil
        }

        var address = AddressModel()

        address.street = placemark.thoroughfare?.trimmingCharacters(in: .whitespaces)
        address.city = placemark.locality?.trimmingCharacters(in: .whitespaces)
        address.state = placemark.administrativeArea?.trimmingCharacters(in: .whitespaces)
        address.country = placemark.country?.trimmingCharacters(in: .whitespaces)
        address.postalCode = placemark.postalCode?.trimmingCharacters(in: .whitespaces)

        return address
    }
}
