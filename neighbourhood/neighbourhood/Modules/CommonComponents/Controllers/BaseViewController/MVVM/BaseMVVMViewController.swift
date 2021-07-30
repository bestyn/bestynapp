//
//  BaseMVVMViewController.swift
//  neighbourhood
//
//  Created by iphonovv on 23.11.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

class BaseMVVMViewController<Configurator: BaseConfiguratorType, ViewModel: BaseViewModel<Configurator>>: BaseViewController {
    
    let viewModel: ViewModel
 
    init(viewModel: ViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
