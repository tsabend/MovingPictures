//
//  VideoWriter.swift
//  PictoGif
//
//  Created by Thomas Abend on 6/11/16.
//  Copyright © 2016 Sean. All rights reserved.
//

import AVFoundation
import UIKit
import Result

public typealias ImageTime = (image: UIImage, time: Double)

/// A wrapper around AVAssetWriting designed for writing photos to videos.
/// Much like the underlying AVAssetWriter, this class is single-use.
public class MovingPictures {
    
    private let settings: RenderSettings
    /// - parameter imageTimes: An array of imageTimes. Must not be empty.
    /// - render settings: The settings to use for rendering the images into video
    /// - throws: Will throw an error if called with an empty list of imageTimes
    public init(settings: RenderSettings) {
        self.settings = settings
    }
    
    /// Renders the images into a video and calls the completion when it is finished.
    /// Completion will either include the URL where you will find the video or throw
    /// an error if writing failed.
    public func render(imageTimes: [ImageTime], completion: (Result<NSURL, NSError>) -> Void) {
        // The VideoWriter will fail if a file exists at the URL, so clear it out first.
        do {
            try NSFileManager.defaultManager().removeItemAtPath(self.settings.outputURL.path!)
        } catch let error as NSError {
            if error.code != 4 {
                completion(Result { throw error })
            }
        }
        
        // Render the images into a video
        self._render(imageTimes, completion: completion)
    }
    
    // MARK: - Private API
    
    /// Renders a video by appending pixel buffers until it reaches the end of
    /// the content.
    /// - parameter imageTimes: the images to write to video
    /// - parameter completion: called when the render is completed or errored. Unwrap the result to check for errors.
    private func _render(imageTimes: [ImageTime], completion: (Result<NSURL, NSError>) -> Void) {
        guard let videoWriter = self.videoWriter else { completion(Result { throw(VideoWritingError.InvalidWriter)}); return}

        let queue = dispatch_queue_create("mediaInputQueue", nil)
        videoWriterInput.requestMediaDataWhenReadyOnQueue(queue) {
            do {
                try self.appendPixelBuffers(imageTimes)
                self.videoWriterInput.markAsFinished()
                
                let totalDuration = imageTimes.reduce(0) { $0 + $1.time }
                videoWriter.endSessionAtSourceTime(totalDuration.inSeconds)
                
                videoWriter.finishWritingWithCompletionHandler {
                    dispatch_async(dispatch_get_main_queue()) {
                        completion(Result { self.settings.outputURL })
                    }
                }
            } catch let error {
                dispatch_async(dispatch_get_main_queue()) {
                    completion(Result { throw error})
                }
            }
        }
    }
    
    
    /// Adds images to the video
    /// - throws: a `VideoWritingError` if the videoWriter fails to addImages.
    private func appendPixelBuffers(imageTimes: [ImageTime]) throws {
        var elapsed = 0.inSeconds
        for imageTime in imageTimes {
            guard self.videoWriterInput.readyForMoreMediaData else { throw VideoWritingError.InvalidWriter }
            
            let frameDuration = imageTime.time.inSeconds
            try self.addImage(imageTime.image, withPresentationTime: elapsed)
            elapsed = CMTimeAdd(elapsed, frameDuration)
        }
        // Send the final frame a second time so the video writes all the way to completion.
        try self.addImage(imageTimes.last!.image, withPresentationTime: elapsed)

    }
    
    /// Adds an image to the video at the given presentation time.
    /// - parameter image: The image to add to the video
    /// - parameter presentationTime: The time for the image to be added on. Be sure not to add images at times that already have data or an error will throw.
    private func addImage(image: UIImage, withPresentationTime presentationTime: CMTime) throws {
        let pixelBuffer = try image.toPixelBuffer(pixelBufferAdaptor.pixelBufferPool!, size: self.settings.size, contentMode: self.settings.contentMode)
        let success = pixelBufferAdaptor.appendPixelBuffer(pixelBuffer, withPresentationTime: presentationTime)
        if !success { throw(VideoWritingError.TimingError) }
    }
    
    private lazy var videoWriter: AVAssetWriter? = {
        do {
            let videoWriter = try AVAssetWriter(URL: self.settings.outputURL, fileType: AVFileTypeMPEG4)
            
            guard videoWriter.canApplyOutputSettings(self.settings.outputSettings, forMediaType: AVMediaTypeVideo) else { return nil }
            guard videoWriter.canAddInput(self.videoWriterInput) else { return nil }
            videoWriter.addInput(self.videoWriterInput)
            
            guard self.pixelBufferAdaptor.pixelBufferPool == nil else { return nil }
            guard videoWriter.startWriting() == true else { return nil }
            videoWriter.startSessionAtSourceTime(kCMTimeZero)
            return videoWriter
        } catch {
            return nil
        }
    }()
    
    private lazy var videoWriterInput: AVAssetWriterInput = {
        return AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: self.settings.outputSettings)
    }()
    
    private lazy var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor = {
        return AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: self.videoWriterInput,
            sourcePixelBufferAttributes: self.settings.pixelAttributes)
    }()
}


public enum VideoWritingError : ErrorType {
    case TimingError
    case InvalidWriter
    case MissingPixelBuffer
    case NoImages
}
