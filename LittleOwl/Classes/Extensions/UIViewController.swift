//
//  UIViewController.swift
//  LittleOwl
//
//  Created by Carlos Duclos on 8/22/18.
//

import Foundation
import UIKit

extension UIViewController {
    
    func alert(title: String? = "", message: String, completion: (() -> Void)? = nil) {
        
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancel = UIAlertAction(title: title, style: .cancel, handler: { _ in
            completion?()
        })
        
        controller.addAction(cancel)
        self.present(controller, animated: true, completion: nil)
    }
}
