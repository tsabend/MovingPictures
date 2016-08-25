// https://github.com/Quick/Quick

import Quick
import Nimble
import Result
import AVFoundation
@testable import MovingPictures

class MovingPicturesSpec: QuickSpec {
    override func spec() {
        describe("render") {
            let images: [UIImage] = [
                UIImage(named: "dog1")!,
                UIImage(named: "dog2")!,
                UIImage(named: "dog3")!
            ]
            let times: [Double] = [1, 1.5, 1.2]
            let imageTimes: [ImageTime] = Array(zip(images, times))
            let settings = RenderSettings(size: images.first!.size, videoFilename: "foo")

            it("calls the completion with a result containing the url of a video") {
                let writer = MovingPictures(settings: settings)
                writer.render(imageTimes) { (result: Result<NSURL, NSError>) in
                    let url = try! result.dematerialize()
                    let asset = AVAsset(URL: url)
                    expect(asset).notTo(beNil())
                }
            }
            
            it("calls the completion with a video that has a duration of the combined images") {
                let writer = MovingPictures(settings: settings)
                writer.render(imageTimes) { (result: Result<NSURL, NSError>) in
                    let url = try! result.dematerialize()
                    let asset = AVAsset(URL: url)
                    let time = (3.7).inSeconds
                    expect(asset.duration) == time
                }
            }
            
            it("calls the completion with a video of the type specified by the render settings") {
                let movSettings = RenderSettings(size: images.first!.size, videoFilename: "foo", videoExtension: .MOV)
                let movWriter = MovingPictures(settings: settings)
                movWriter.render(imageTimes) { (result: Result<NSURL, NSError>) in
                    let url = try! result.dematerialize()
                    expect(url.pathExtension) == movSettings.videoExtension.rawValue
                }
                let mp4Settings = RenderSettings(size: images.first!.size, videoFilename: "foo", videoExtension: .MP4)
                let mp4Writer = MovingPictures(settings: settings)
                mp4Writer.render(imageTimes) { (result: Result<NSURL, NSError>) in
                    let url = try! result.dematerialize()
                    expect(url.pathExtension) == mp4Settings.videoExtension.rawValue
                }
            }
            
            it("can be called twice with the same filePath without erroring") {
                let writer1 = MovingPictures(settings: settings)
                
                writer1.render(imageTimes) { (result1: Result<NSURL, NSError>) in
                    
                    let writer2 = MovingPictures(settings: settings)
                    writer2.render([(images.first!, 5)]) { (result2: Result<NSURL, NSError>) in
                        let url1 = try! result1.dematerialize()
                        let url2 = try! result1.dematerialize()
                        
                        expect(NSData(contentsOfURL: url1)) != NSData(contentsOfURL: url2)
                    }
                }
                
            }
            
            context("no images are passed in") {
                it("calls the completion throwing a VideoWritingError.NoImages error") {
                    let writer = MovingPictures(settings: settings)
                    writer.render([]) { (result: Result<NSURL, NSError>) in
                        expect {
                            try result.dematerialize()
                        }.to(throwError(VideoWritingError.NoImages))
                    }
                }
            }
        }
    }
}
