//
//  FileHelper.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/9/27.
//

import Foundation

class FileHelper {
    static func removeFile(at path: String) {
        let fileManager = FileManager.default
        try? fileManager.removeItem(atPath: path)
    }
    
    static func createDir(at path: String) {
       let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: path) {
            do {
               try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
            } catch {
                print(error)
            }
        }
    }
    
    /// 清空指定目录，但不删除目录
    /// - Parameter path: 目录所在路径
    static func cleanDir(at path: String) {
        let fileManager = FileManager.default
        if let dirEnumerator = fileManager.enumerator(atPath: path) {
            for name in dirEnumerator {
                if let partName = name as? String {
                    removeFile(at: path + partName)
                }
            }
        }
    }
    
    static func fileExists(at path: String) -> Bool {
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: path)
    }
}


extension String {
    public var fileURL: URL {
        URL(fileURLWithPath: self)
    }
}

