//
//  PhotoRetriever.swift
//  picdive
//
//  Created by Thomas Abend on 4/23/16.
//  Copyright © 2016 Sean. All rights reserved.
//

import UIKit
import Photos

/// A thin wrapper around PHFetching
struct PhotoRetriever {

    private var thumbOptions: PHImageRequestOptions
    private var fetchOptions: PHFetchOptions
    private var photos: PHFetchResult?
    
    init() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        self.fetchOptions = fetchOptions
        let options = PHImageRequestOptions()
        options.synchronous = true
        options.deliveryMode = .Opportunistic
        self.thumbOptions = options
        self.reloadData()
    }
    
    mutating func reloadData() {
        self.photos = PHAsset.fetchAssetsWithMediaType(PHAssetMediaType.Image, options: self.fetchOptions)
    }
    
    var count: Int {
        return self.photos?.count ?? 0
    }
    
    subscript(index: Int) -> PHAsset? {
        guard let photos = self.photos else { return nil }
        guard index < self.count else { return nil }
        return photos[index] as? PHAsset
    }
    
    func getThumb(atIndex index: Int, withCompletion completion: (UIImage?) -> Void) {
        guard let object = self[index] else { completion(nil); return }
        
        let contentMode: PHImageContentMode = PHImageContentMode.AspectFill
        let sideLength = UIScreen.mainScreen().bounds.width / 4
        let size = CGSize(width: sideLength, height: sideLength)
        PHImageManager.defaultManager().requestImageForAsset(object, targetSize: size, contentMode: contentMode, options: self.thumbOptions) {
            image, info in
            completion(image)
        }
    }
    
    
    func getImage(asset: PHAsset, queryCallback: (UIImage? -> Void)) {
        let options = PHImageRequestOptions()
        let contentMode: PHImageContentMode = PHImageContentMode.Default
        options.synchronous = true
        options.deliveryMode = .HighQualityFormat
        
        
        PHImageManager.defaultManager().requestImageForAsset(asset, targetSize: PHImageManagerMaximumSize, contentMode: contentMode, options: options) {
            image, info in
            queryCallback(image)
        }
    }
}