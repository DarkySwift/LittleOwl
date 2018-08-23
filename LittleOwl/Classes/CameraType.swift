//
//  CameraTyoe.swift
//  Owl
//
//  Created by Carlos Duclos on 8/17/18.
//

import Foundation

public enum CameraType {
    case photo
    case video(Int)
    
    var maxDuration: Int {
        switch self {
        case .photo: return 0
        case .video(let duration): return duration
        }
    }
    
    var isVideo: Bool {
        switch self {
        case .photo: return false
        case .video: return true
        }
    }
      
    var isPhoto: Bool {
        switch self {
        case .photo: return true
        case .video: return false
        }
    }
        
}
