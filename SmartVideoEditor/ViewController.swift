//
//  ViewController.swift
//  SmartVideoEditor
//
//  Created by JinFeng on 2021/9/20.
//

import UIKit
import FileBox
import CoreImage

class ViewController: UIViewController {

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
//        try? FileManager.default.removeItem(atPath: VideoRecordConfig.defaultRecordOutputDirPath)
        view.contentMode = .scaleAspectFit
        let uiImage = UIImage(named: "biaozhun")
        let ciImage = CIImage.init(image: uiImage!)
    }

    @IBAction func onClickRecord(_ sender: Any) {
        let vc = RecordViewController()
//        let vc = WCLRecordViewController()
        let navi = UINavigationController(rootViewController: vc)
//        navi.modalPresentationStyle = .fullScreen
        navigationController?.present(navi, animated: true, completion: nil)
    }
    
    @IBAction func onClickLookForDir(_ sender: UIButton) {
        FileBox.default.openRecently(dir: FileBox.cachePath())
    }
    
    @IBAction func onClickWclRecord(_ sender: Any) {
        let vc = CustomVideoCompositionViewController()
//        let vc = VideoEditorViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}

