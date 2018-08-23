//
//  UIImage.swift
//  Owl
//
//  Created by Carlos Duclos on 8/17/18.
//

import Foundation
import UIKit

func CGRectCenteredInRect(rect: CGRect, mainRect: CGRect) -> CGRect {
    let xOffset: CGFloat = mainRect.midX - rect.midX
    let yOffset: CGFloat = mainRect.midY - rect.midY
    return rect.offsetBy(dx: xOffset, dy: yOffset)
}

// Calculate the destination scale for filling
func CGAspectScaleFill(sourceSize: CGSize, destRect: CGRect) -> CGFloat {
    let destSize: CGSize = destRect.size
    let scaleW: CGFloat = destSize.width / sourceSize.width
    let scaleH: CGFloat = destSize.height / sourceSize.height
    return max(scaleW, scaleH)
}

func CGRectAspectFillRect(sourceSize: CGSize, destRect: CGRect) -> CGRect {
    let destSize: CGSize = destRect.size
    let destScale = CGAspectScaleFill(sourceSize: sourceSize, destRect: destRect)
    let newWidth: CGFloat = sourceSize.width * destScale
    let newHeight: CGFloat = sourceSize.height * destScale
    let dWidth: CGFloat = (destSize.width - newWidth) / 2.0
    let dHeight: CGFloat = (destSize.height - newHeight) / 2.0
    let rect = CGRect(x: dWidth, y: dHeight, width: newWidth, height: newHeight)
    return rect
}

func imageNamed(_ name: String) -> UIImage? {
    let bundle = Bundle(for: CameraViewController.self)
    return UIImage(named: name, in: bundle, compatibleWith: nil)
}

extension UIImage {
    
    func applyAspectFill(in bounds: CGRect) -> UIImage? {
        var destRect: CGRect
        UIGraphicsBeginImageContext(bounds.size)
        let rect: CGRect = CGRectAspectFillRect(sourceSize: size, destRect: bounds)
        destRect = CGRectCenteredInRect(rect: rect, mainRect: bounds)
        draw(in: destRect)
        let newImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}
