//
//  AVAuthorization.swift
//  AVAuthorization
//
//  Created by jinfeng on 2021/9/22.
//

import UIKit
import AVFoundation

class VideoPermission: NSObject {
    static func currentVideoStatus() -> AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    static func currentAudioStatus() -> AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .audio)
    }
    
    static func requestAuth(handle video: @escaping (Bool) -> Void, audio:  @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            video(granted)
        }
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            audio(granted)
        }
    }
    
    static func recordPermission() -> Bool {
        AVAudioSession.sharedInstance().recordPermission == .granted
    }
}
