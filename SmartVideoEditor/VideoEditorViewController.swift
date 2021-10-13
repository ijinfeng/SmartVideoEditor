//
//  VideoEditorViewController.swift
//  SmartVideoEditor
//
//  Created by jinfeng on 2021/10/12.
//

import UIKit
import AVFoundation
import VideoEditor
import SnapKit

class MyCell: UICollectionViewCell {
    
    var image: UIImage? {
        didSet {
            if let image = self.image {
                imageView.image = image
            }
        }
    }
    
    private var imageView: UIImageView = UIImageView()
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class VideoEditorViewController: UIViewController {
    private let showImageView = UIImageView()
    
    let collection: UICollectionView = UICollectionView.init(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    
    var images: [UIImage?] = []
    var total: Int = 0
    
    let itemSize = CGSize(width: 160, height: 400)
    
    var reader: VideoInfoReader?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(showImageView)
        showImageView.snp.makeConstraints { make in
            make.top.equalTo(88)
            make.size.equalTo(CGSize(width: 65, height: 100))
            make.centerX.equalTo(view)
        }
        
        collection.delegate = self
        collection.dataSource = self
        collection.register(MyCell.self, forCellWithReuseIdentifier: "cell")
        
        if let layout = collection.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
        }
        
        view.addSubview(collection)
        collection.backgroundColor = .white
        collection.snp.makeConstraints { make in
            make.left.right.equalTo(view)
            make.bottom.equalTo(0)
            make.height.equalTo(100)
        }
        
        view.backgroundColor = .white
        
        if let path = Bundle.main.path(forResource: "vap", ofType: "mp4") {
            let asset = AVAsset(url: URL(fileURLWithPath: path))
            print(asset)
            // AVURLAsset
            print("dur: \(asset.duration)")
            
        // file:///Users/Cranz/Library/Developer/CoreSimulator/Devices/29DE5B13-7EAB-4DD9-B830-C5FDF944111F/data/Containers/Bundle/Application/66706578-BF76-4170-A6E0-A103D0CED827/SmartVideoEditor.app/vap.mp4
            reader = VideoInfoReader.init(videoPath: path)
            reader?.generateImages(by: 0.5, maximumSize: .zero) { requestTime, outputImage, index, total in
                self.total = total
                self.images.append(outputImage)
                print("- req: \(requestTime), \n index: \(index), \n total: \(total), \n outImage: \(outputImage == nil ? "nil":"image")")
                self.collection.reloadData()
                return true
            }
        }
    }
   
}

extension VideoEditorViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! MyCell
        cell.image = self.images[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: 65, height: 100)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetX = scrollView.contentOffset.x
        let boundsWidth = scrollView.contentSize.width
        
        let scale = offsetX / boundsWidth
        
        reader?.tryAsyncRead(completionHandler: { info in
            let time = info.duration * scale
            self.reader?.generateImage(at: time, maximumSize: CGSize(width: 65, height: 100), async: { outputImage in
                if outputImage == nil {
                    print("nil+++++++++++++++")
                }
                if let image = outputImage {
                    self.showImageView.image = image
                }
            })
        })
    }
}
 
