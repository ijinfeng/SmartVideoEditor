//
//  AVAuthorization.swift
//  AVAuthorization
//
//  Created by jinfeng on 2021/9/22.
//

import UIKit
import AVFoundation

class AVAuthorization: NSObject {
    static func currentStatus() -> AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    static func requestAuth(_ handle: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            handle(granted)
        }
    }
}
