//
//  OverlayProvider.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/11/9.
//

import Foundation
import CoreGraphics

public protocol OverlayProvider: TimingProvider, VisualProvider {
    var frame: CGRect { set get }
}