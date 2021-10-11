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
    
    func didStopRecord()
    
    func didFinishPartRecord(outputURL: URL)
    
    func didRecording(seconds: Float64)
}

extension VideoRecordDelegate {
    func didStartPartRecord(outputURL: URL) {}
    func didStopRecord() {}
    func didFinishPartRecord(outputURL: URL) {}
    func didRecording(seconds: Float64) {}
}
