//
//  ImageAnimator.swift
//  PictoGif
//
//  Created by Thomas Abend on 6/10/16.
//  Copyright © 2016 Sean. All rights reserved.
//

// modified from http://stackoverflow.com/questions/3741323/how-do-i-export-uiimage-array-as-a-movie
import AVFoundation
import UIKit
import Result

public typealias ImageTime = (image: UIImage, time: Double)


/// A wrapper around AVAssetWriting designed for writing photos to videos.
/// Much like the underlying AVAssetWriter, this class is single-use.
/// If you want to write to files multiple times, you must use a new instance of ImageAnimator each time.
public class ImageAnimator {
    
    // Apple suggests a timescale of 600 because it's a multiple of standard video rates 24, 25, 30, 60 fps etc.
    static let kTimescale: Double = 600
    
    let settings: RenderSettings
    let videoWriter: VideoWriter
    let imageTimes: [ImageTime]
    lazy var totalDuration: Double = self.imageTimes.map{$0.time}.reduce(0, combine: +)
    
    /// - parameter imageTimes: An array of imageTimes. Must not be empty.
    /// - render settings: The settings to use for rendering the images into video
    /// - throws: Will throw an error if called with an empty list of imageTimes
    public init(imageTimes: [ImageTime], renderSettings: RenderSettings) {
        self.settings = renderSettings
        self.videoWriter = VideoWriter(renderSettings: settings)
        self.imageTimes = imageTimes
    }
    
    /// Renders the images into a video and calls the completion when it is finished.
    /// Completion will either include the URL where you will find the video or throw
    /// an error if writing failed.
    public func render(completion: (Result<NSURL, VideoWritingError>) -> Void) {
        // The VideoWriter will fail if a file exists at the URL, so clear it out first.
        do {
            try NSFileManager.defaultManager().removeItemAtPath(self.settings.outputURL.path!)
        } catch let error as NSError {
            if error.code != 4 {
                completion(Result { throw error })
            }
        }
        
        // Render the images into a video
        self.videoWriter.render(self.appendPixelBuffers, totalDuration: self.totalDuration) { (result: Result<Void, VideoWritingError>) in
            do {
                try result.dematerialize()
                completion(Result { _ in self.settings.outputURL })
            } catch let error {
                completion(Result { throw error})
            }
        }
    }

    
    /// Adds images to the video
    /// parameters writer: The `VideoWriter` to use for writing images into video.
    /// - returns: true when all images have been written. false if the writer is in an invalid state.
    /// - throws: a `VideoWritingError` if the videoWriter fails to addImages.
    private func appendPixelBuffers(writer: VideoWriter) throws -> Bool {
        
        var elapsed = self.time(inSeconds: 0)
        for imageTime in self.imageTimes {
            guard writer.isReadyForData else { return false }
            
            let frameDuration = self.time(inSeconds: imageTime.time)
            try writer.addImage(imageTime.image, withPresentationTime: elapsed)
            elapsed = CMTimeAdd(elapsed, frameDuration)
        }
        // Send the final frame a second time so the video writes all the way to completion.
        try writer.addImage(self.imageTimes.last!.image, withPresentationTime: elapsed)
        
        return true
    }
    
    /// convenience method for making valid times from ImageTimes
    private func time(inSeconds time: Double) -> CMTime {
        return CMTimeMake(Int64(ImageAnimator.kTimescale * time), Int32(ImageAnimator.kTimescale))
    }
        
}

enum ImageAnimatorError: ErrorType {
    case NoImages
}