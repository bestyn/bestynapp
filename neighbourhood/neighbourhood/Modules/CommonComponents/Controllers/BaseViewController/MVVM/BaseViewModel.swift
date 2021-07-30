//
//  BaseViewModel.swift
//  neighbourhood
//
//  Created by iphonovv on 23.11.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

protocol BaseConfiguratorType {
    
}

class BaseViewModel<Conigurator: BaseConfiguratorType> {
    
    init(configurator: Conigurator) {
        
    }
}
