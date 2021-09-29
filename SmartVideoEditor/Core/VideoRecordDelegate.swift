//
//  VideoRecordDelegate.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/9/27.
//

import Foundation
import AVFoundation

public protocol VideoRecordDelegate: AnyObject {
    func didStartPartRecord(outputURL: URL)
    
    func didFinishPartRecord(outputURL: URL)
}

extension VideoRecordDelegate {
    func didStartPartRecord(outputURL: URL) {}
    func didFinishPartRecord(outputURL: URL) {}
}
