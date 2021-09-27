//
//  VideoCollectorDelegate.swift
//  VideoCollectorDelegate
//
//  Created by jinfeng on 2021/9/27.
//

import Foundation
import AVFoundation

public protocol VideoCollectorDelegate: AnyObject {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection)
}
