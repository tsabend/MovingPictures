//
//  MovingPictures.swift
//  MovingPictures
//
//  Created by Thomas Abend on 6/11/16.
//

import AVFoundation
import UIKit
import Result

/// An image and the duration (in seconds) the image should appear in a video
public typealias ImageTime = (image: UIImage, time: Double)

/// The error states for MovingPictures
public enum MovingPicturesError : ErrorType {
    case TimingError
    case InvalidWriter
    case MissingPixelBuffer
    case NoImages
}


/// You use an instance of MovingPictures to write images into videos.
/// Much like the underlying AVAssetWriter, this class is single-use.
public class MovingPictures {
    
    private let settings: RenderSettings
    /// - render settings: The settings to use for rendering the images into video
    public init(settings: RenderSettings) {
        self.settings = settings
    }
    
    /// Renders the images into a video and calls the completion when it is finished.
    /// Completion will either include the URL where you will find the video or throw
    /// an error if writing failed.
    /// - parameter imageTimes: An array of imageTimes. Must not be empty.
    /// - parameter completion: called when the render is completed or errored. Unwrap the result to check for errors.
    public func render(imageTimes: [ImageTime], completion: (Result<NSURL, NSError>) -> Void) {
        guard !imageTimes.isEmpty else { completion(Result { throw MovingPicturesError.NoImages }); return }
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
        guard let videoWriter = self.videoWriter else { completion(Result { throw(MovingPicturesError.InvalidWriter)}); return}

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
        guard self.videoWriterInput.readyForMoreMediaData else { throw MovingPicturesError.InvalidWriter }
        let success = pixelBufferAdaptor.appendPixelBuffer(pixelBuffer, withPresentationTime: presentationTime)
        if !success { throw(MovingPicturesError.TimingError) }
    }
    
    /// The video writer that will write the pixels to a video
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
    
    /// The input used by the pixelBufferAdaptor
    private lazy var videoWriterInput: AVAssetWriterInput = {
        return AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: self.settings.outputSettings)
    }()
    
    /// The pixel buffer adaptor used by the videoWriter
    private lazy var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor = {
        return AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: self.videoWriterInput,
            sourcePixelBufferAttributes: self.settings.pixelAttributes)
    }()
}