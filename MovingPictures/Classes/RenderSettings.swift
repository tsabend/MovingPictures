//
//  RenderSettings.swift
//  PictoGif
//
//  Created by Thomas Abend on 6/11/16.
//  Copyright © 2016 Sean. All rights reserved.
//

import AVFoundation
import UIKit

/// Set options for your video writing
public struct RenderSettings {
    /// The dimensions of the video
    let size: CGSize
    /// The filename for the video
    let videoFilename: String
    /// The file extension for the video
    let videoExtension: VideoExtension
    
    public init(size: CGSize, videoFilename: String, videoExtension: VideoExtension) {
        self.size = size
        self.videoFilename = videoFilename
        self.videoExtension = videoExtension
    }
    
    private let avCodecKey = AVVideoCodecH264
    
    private var cacheDirectoryURL: NSURL {
        // Use the CachesDirectory so the rendered video file sticks around as long as we need it to.
        // Using the CachesDirectory ensures the file won't be included in a backup of the app.
        return try! NSFileManager
            .defaultManager()
            .URLForDirectory(.CachesDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
    }
    
    var outputURL: NSURL {
        return self.cacheDirectoryURL
            .URLByAppendingPathComponent(self.videoFilename)
            .URLByAppendingPathExtension(self.videoExtension.rawValue)
    }
    
    var outputSettings: [String : AnyObject] {
        return [
            AVVideoCodecKey: self.avCodecKey,
            AVVideoWidthKey: NSNumber(float: Float(self.size.width)),
            AVVideoHeightKey: NSNumber(float: Float(self.size.height))
        ]
    }
    
    var pixelAttributes : [String : AnyObject] {
        return [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(unsignedInt: kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: NSNumber(float: Float(self.size.width)),
            kCVPixelBufferHeightKey as String: NSNumber(float: Float(self.size.height))
        ]
    }
}

public enum VideoExtension: String {
    case MOV = "mov"
    case MP4 = "mp4"
}
