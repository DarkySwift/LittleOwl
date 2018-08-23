//
//  String.swift
//  LittleOwl
//
//  Created by Carlos Duclos on 8/22/18.
//

import Foundation

internal func localizedString(_ key: String) -> String {
    let bundle = Bundle(for: CameraViewController.self)
    return NSLocalizedString(key, tableName: "LittleOwl", bundle: bundle, comment: "")
}
