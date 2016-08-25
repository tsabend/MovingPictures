//
//  RenderSettings.swift
//  MovingPictures
//
//  Created by Thomas Abend on 6/11/16.
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
    /// The contentMode used to render the images as they are written to the video
    let contentMode: ContentMode
    
    public init(size: CGSize, videoFilename: String, videoExtension: VideoExtension = .MOV, contentMode: ContentMode = .ScaleAspectFit) {
        self.size = size
        self.videoFilename = videoFilename
        self.videoExtension = videoExtension
        self.contentMode = contentMode
    }
    
    
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
            AVVideoCodecKey: AVVideoCodecH264,
            AVVideoWidthKey: self.size.width,
            AVVideoHeightKey: self.size.height
        ]
    }
    
    var pixelAttributes : [String : AnyObject] {
        return [
            kCVPixelBufferPixelFormatTypeKey as String: Float(kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: self.size.width,
            kCVPixelBufferHeightKey as String: self.size.height
        ]
    }
}

public enum VideoExtension: String {
    case MOV = "mov"
    case MP4 = "mp4"
}

public enum ContentMode {
    case ScaleAspectFill, ScaleAspectFit
}