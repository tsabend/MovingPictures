//
//  Double+MovingPictures.swift
//  Pods
//
//  Created by Thomas Abend on 8/18/16.
//
//

import AVFoundation

extension Double {
    /// convenience method for making valid times from ImageTimes
    var inSeconds: CMTime {
        // Apple suggests a timescale of 600 because it's a multiple of standard video rates 24, 25, 30, 60 fps etc.
        let timescale: Double = 600
        return CMTimeMake(Int64(timescale * self), Int32(timescale))
    }
}