//
//  Device.swift
//  neighbourhood
//
//  Created by Dioksa on 10.07.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation
import DeviceKit

extension Device {
    var isIphonePlus: Bool {
        return allPlusSizedDevicesAndSims.contains(self)
    }
    
    var isIphoneXAndAfter: Bool {
        return allXSeriesDevicesAndSims.contains(self)
    }
    
    var isBeforeIphoneX: Bool {
        return allSmallDevicesAndSims.contains(self)
    }
}

private let allPlusSizedDevicesAndSims: [Device] = {
    return Device.allPlusSizedDevices + Device.allSimulatorPlusSizedDevices
}()

private let allSmallDevicesAndSims: [Device] = {
    let devices: [Device] = [.iPhoneSE, .iPhone5, .iPhone5s, .iPhone5c, .iPhone6, .iPhone6s, .iPhone7, .iPhone8, .iPhone8Plus]
    return devices + devices.map(Device.simulator)
}()

private let allXSeriesDevicesAndSims: [Device] = {
    return Device.allDevicesWithSensorHousing + Device.allSimulatorDevicesWithSensorHousing
}()
