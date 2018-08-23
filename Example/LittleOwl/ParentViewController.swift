//
//  ParentViewController.swift
//  Owl_Example
//
//  Created by Carlos Duclos on 8/17/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import Foundation
import UIKit
import Owl

class ParentViewController: UIViewController {
    
    public var cameraType: CameraType = .photo
    public var maxDuration: Int = 0
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - Lifecycle
    
    init(cameraType: CameraType, maxDuration: Int) {
        super.init(nibName: nil, bundle: nil)
        
        self.cameraType = cameraType
        self.maxDuration = maxDuration
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cameraController = CameraViewController(type: cameraType, maxDuration: maxDuration)
        cameraController.willMove(toParentViewController: self)
        addChildViewController(cameraController)
        view.addSubview(cameraController.view)
        cameraController.didMove(toParentViewController: self)
    }
}
