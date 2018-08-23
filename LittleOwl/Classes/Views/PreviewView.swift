//
//  PreviewView.swift
//  Owl
//
//  Created by Carlos Duclos on 8/17/18.
//

import Foundation
import UIKit
import AVFoundation

class PreviewView: UIView {
    
    override final class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    public var session: AVCaptureSession? {
        get {
            return videoPreviewLayer?.session
        }
        set {
            videoPreviewLayer?.session = newValue
        }
    }
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer? {
        return self.layer as? AVCaptureVideoPreviewLayer
    }
}
