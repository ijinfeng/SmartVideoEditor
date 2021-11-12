//
//  OverlayProvider.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/11/9.
//

import Foundation
import CoreGraphics

public protocol OverlayProvider: VisualProvider {
    var frame: CGRect { set get }
    var extent: CGRect { set get }
    var userTransform: CGAffineTransform { set get }
}
