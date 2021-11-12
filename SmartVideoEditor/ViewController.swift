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

    var ciImage: CIImage?
    
    let imageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
//        try? FileManager.default.removeItem(atPath: VideoRecordConfig.defaultRecordOutputDirPath)
        view.contentMode = .scaleAspectFit
        let uiImage = UIImage(named: "biaozhun")
        ciImage = CIImage.init(image: uiImage!)
        
        imageView.image = uiImage
        
        
        view.addSubview(imageView)
        imageView.frame = CGRect(x: 20, y: 300, width: 100, height: 100)
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard var image = ciImage else {
            return
        }
        image = image.transformed(by: CGAffineTransform.init(rotationAngle: angle))
        ciImage = image
        imageView.image = UIImage(ciImage: image)
        angle += 0.1
        print("旋转---\(angle)")
    }
}

var angle: CGFloat = 0
