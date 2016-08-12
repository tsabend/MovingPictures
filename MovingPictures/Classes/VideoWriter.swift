//
//  VideoWriter.swift
//  PictoGif
//
//  Created by Thomas Abend on 6/11/16.
//  Copyright © 2016 Sean. All rights reserved.
//

import AVFoundation
import UIKit

public enum Result<T: Any> {
    case Success(T)
    case Failure(ErrorType)
}

public extension Result {
    
    init(_ f: () throws -> T) {
        do {
            self = .Success(try f())
        } catch let e {
            self = .Failure(e)
        }
    }
    
    func unwrap() throws -> T {
        switch self {
        case let .Success(x):
            return x
        case let .Failure(e):
            throw e
        }
    }
}

// The class that does the actual video writing.
class VideoWriter {
    
    let renderSettings: RenderSettings
    init(renderSettings: RenderSettings) {
        self.renderSettings = renderSettings
    }
    // MARK: - Public API
    
    /// Renders a video by appending pixel buffers until it reaches the end of
    /// the content.
    /// - parameter appendPixelBuffers: a function that writes image data into the videoWriter. Returns true when all of the pixels have been written.
    /// - parameter totalDuration: The total duration of the final video. 
    /// - parameter completion: called when the render is completed or errored. Unwrap the result to check for errors.
    func render(appendPixelBuffers: (VideoWriter) throws -> Bool, totalDuration: Double,  completion: (Result<Void>) -> Void) {
        
        guard let videoWriter = self.videoWriter else { completion(Result { throw(VideoWritingError.InvalidWriter)}); return}
        
        let queue = dispatch_queue_create("mediaInputQueue", nil)
        videoWriterInput.requestMediaDataWhenReadyOnQueue(queue) {
            do {
                let isFinished = try appendPixelBuffers(self)
                if isFinished {
                    self.videoWriterInput.markAsFinished()
                    let endTime = CMTimeMake(Int64(ImageAnimator.kTimescale * totalDuration), Int32(ImageAnimator.kTimescale))
                    videoWriter.endSessionAtSourceTime(endTime)
                    videoWriter.finishWritingWithCompletionHandler() {
                        dispatch_async(dispatch_get_main_queue()) {
                            completion(Result {})
                        }
                    }
                } else {
                    // continue processing
                }
            } catch let error {
                completion(Result { throw error})
            }
        }
    }
    
    /// Adds an image to the video at the given presentation time.
    /// - parameter image: The image to add to the video
    /// - parameter presentationTime: The time for the image to be added on. Be sure not to add images at times that already have data or an error will throw.
    func addImage(image: UIImage, withPresentationTime presentationTime: CMTime) throws {
        let pixelBuffer = try VideoWriter.pixelBufferFromImage(image, pixelBufferPool: pixelBufferAdaptor.pixelBufferPool!, size: renderSettings.size)
        let success = pixelBufferAdaptor.appendPixelBuffer(pixelBuffer, withPresentationTime: presentationTime)
        if !success { throw(VideoWritingError.TimingError) }
    }
    
    /// Returns whether the videoWriter is ready to write the next image
    var isReadyForData: Bool {
        return self.videoWriterInput.readyForMoreMediaData
    }
    
    // MARK: - Private API
    private lazy var videoWriter: AVAssetWriter? = {
        do {
            let videoWriter = try AVAssetWriter(URL: self.renderSettings.outputURL, fileType: AVFileTypeMPEG4)
            
            guard videoWriter.canApplyOutputSettings(self.renderSettings.outputSettings, forMediaType: AVMediaTypeVideo) else { return nil }
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
    
    lazy var videoWriterInput: AVAssetWriterInput = {
        return AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: self.renderSettings.outputSettings)
    }()
    
    lazy var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor = {
        return AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: self.videoWriterInput,
            sourcePixelBufferAttributes: self.renderSettings.pixelAttributes)
    }()
    
    private static func pixelBufferFromImage(image: UIImage, pixelBufferPool: CVPixelBufferPool, size: CGSize) throws -> CVPixelBuffer {
        
        var pixelBufferOut: CVPixelBuffer?
        
        let success = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBufferOut)
        guard success == kCVReturnSuccess else { throw(VideoWritingError.MissingPixelBuffer) }
        
        let pixelBuffer = pixelBufferOut!
        
        CVPixelBufferLockBaseAddress(pixelBuffer, 0)
        
        let data = CVPixelBufferGetBaseAddress(pixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGBitmapContextCreate(data, Int(size.width), Int(size.height),
                                            8, CVPixelBufferGetBytesPerRow(pixelBuffer), rgbColorSpace, CGImageAlphaInfo.PremultipliedFirst.rawValue)
        
        CGContextClearRect(context, CGRectMake(0, 0, size.width, size.height))
        
        let horizontalRatio = size.width / image.size.width
        let verticalRatio = size.height / image.size.height
        //aspectRatio = max(horizontalRatio, verticalRatio) // ScaleAspectFill
        let aspectRatio = min(horizontalRatio, verticalRatio) // ScaleAspectFit
        
        let newSize = CGSize(width: image.size.width * aspectRatio, height: image.size.height * aspectRatio)
        
        let x = newSize.width < size.width ? (size.width - newSize.width) / 2 : 0
        let y = newSize.height < size.height ? (size.height - newSize.height) / 2 : 0
        
        CGContextDrawImage(context, CGRectMake(x, y, newSize.width, newSize.height), image.CGImage)
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0)
        
        return pixelBuffer
    }
}


enum VideoWritingError : ErrorType {
    case TimingError
    case InvalidWriter
    case MissingPixelBuffer
}