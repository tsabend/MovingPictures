//
//  ImageAnimator.swift
//  MovingPictures
//
//  Created by Thomas Abend on 6/10/16.
//

// modified from http://stackoverflow.com/questions/3741323/how-do-i-export-uiimage-array-as-a-movie
import AVFoundation

extension UIImage {
    func toPixelBuffer(pixelBufferPool: CVPixelBufferPool, size: CGSize, contentMode: ContentMode) throws -> CVPixelBuffer {
        
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
        
        let horizontalRatio = size.width / self.size.width
        let verticalRatio = size.height / self.size.height
        
        var aspectRatio: CGFloat
        switch contentMode {
        case .ScaleAspectFill:
            aspectRatio = max(horizontalRatio, verticalRatio)
        case .ScaleAspectFit:
            aspectRatio = min(horizontalRatio, verticalRatio)
        }
        
        let newSize = CGSize(width: self.size.width * aspectRatio, height: self.size.height * aspectRatio)
        
        let x = newSize.width < size.width ? (size.width - newSize.width) / 2 : 0
        let y = newSize.height < size.height ? (size.height - newSize.height) / 2 : 0
        
        CGContextDrawImage(context, CGRectMake(x, y, newSize.width, newSize.height), self.CGImage)
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0)
        
        return pixelBuffer
    }
}