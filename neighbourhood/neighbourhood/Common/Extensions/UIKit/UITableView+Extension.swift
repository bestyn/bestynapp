//
//  UITableView+Extension.swift
//  neighbourhood
//
//  Created by Dioksa on 17.07.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

extension UITableView {
    public func scrollToBottom(row: Int, section: Int) {
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: row, section: section)
            self.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    public func scrollToTop() {
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: 0, section: 0)
            self.scrollToRow(at: indexPath, at: .top, animated: true)
        }
    }
}
