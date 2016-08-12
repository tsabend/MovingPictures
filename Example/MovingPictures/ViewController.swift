//
//  ViewController.swift
//  MovingPictures
//
//  Created by Thomas Abend on 8/12/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//


import UIKit
import MovingPictures
import AVKit
import AVFoundation

class ImageCell: UICollectionViewCell {
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var imageView: UIImageView!
}


class ViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    let photos: [UIImage] = [
        UIImage(named: "dog1")!,
        UIImage(named: "dog2")!,
        UIImage(named: "dog3")!
    ]
    var playerViewController: AVPlayerViewController {
        return self.childViewControllers.last as! AVPlayerViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.playerViewController.view.frame = self.playerViewController.view.superview!.bounds
    }
    
    @IBAction func makeVideo(sender: AnyObject) {
        self.view.endEditing(true)
        let cells = (0..<3)
            .map { NSIndexPath(forItem: $0, inSection: 0) }
            .map { self.collectionView.cellForItemAtIndexPath($0) as! ImageCell }
        let images: [UIImage] = cells.map { $0.imageView.image! }
        let times = cells.map { Double($0.textField.text ?? "0" )!}
        let imageTimes: [ImageTime] = Array(zip(images, times))
        
        let settings = RenderSettings(size: images.first!.size, videoFilename: "foo", videoExtension: .MOV)
        let writer = try! ImageAnimator(imageTimes: imageTimes, renderSettings: settings)
        writer.render { (result: Result<NSURL>) in
            do {
                let url = try result.unwrap()
                let asset = AVAsset(URL: url)
                let item = AVPlayerItem(asset: asset)
                self.playerViewController.player = AVPlayer(playerItem: item)
                self.playerViewController.player?.play()
            } catch {
                print(error)
            }
        }
        
        
        
        
    }

}

// MARK: - CollectionView
extension ViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        if let cell = self.collectionView.dequeueReusableCellWithReuseIdentifier("ImageCell", forIndexPath: indexPath) as? ImageCell {
            cell.imageView.image = self.photos[indexPath.item]
            return cell
        }
        return UICollectionViewCell()
    }

}