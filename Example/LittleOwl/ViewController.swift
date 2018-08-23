//
//  ViewController.swift
//  Owl
//
//  Created by Carlos Duclos on 08/17/2018.
//  Copyright (c) 2018 Carlos Duclos. All rights reserved.
//

import UIKit
import LittleOwl
import AVFoundation

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func showTapped(_ sender: Any) {
        
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            let cameraController = CameraViewController(type: .video, maxDuration: 50)
            cameraController.didSelectVideo = { url in
                print("url", url?.absoluteString ?? "")
                cameraController.dismiss(animated: true, completion: nil)
            }
            cameraController.didSelectPhoto = { image in
                cameraController.dismiss(animated: true, completion: nil)
            }
            cameraController.didClose = {
                cameraController.dismiss(animated: true, completion: nil)
            }
            present(cameraController, animated: true)
            
        case .denied:
            print("Denied")
            
        case .notDetermined:
            print("notDetermined")
            
        case .restricted:
            print("restricted")
        }
        
        
    }

}

