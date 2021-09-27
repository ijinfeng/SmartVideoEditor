//
//  VideoRecordDelegate.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/9/27.
//

import Foundation
import AVFoundation

public protocol VideoRecordDelegate: AnyObject {
    func didStartRecord(outputURL: URL)
    
    func didFinishRecord(outputURL: URL)
}

extension VideoRecordDelegate {
    func didStartRecord(outputURL: URL) {}
}
