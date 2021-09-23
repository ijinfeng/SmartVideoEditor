//
//  VideoRecordConfig.swift
//  VideoRecordConfig
//
//  Created by jinfeng on 2021/9/23.
//

import UIKit

public class VideoRecordConfig: NSObject {
    /// 录制的最大时长
    var maxRecordedDuration: TimeInterval = 15
}

extension VideoRecordConfig {
    public static let defaultRecordPath: String =
        NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! + "/record"
}
