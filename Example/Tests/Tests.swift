// https://github.com/Quick/Quick

import Quick
import Nimble
import Result
import MovingPictures
import AVFoundation

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
                expect(1) == 2
                let writer = MovingPictures(settings: settings)
                writer.render(imageTimes) { (result: Result<NSURL, NSError>) in
                    do {
                        let url = try result.dematerialize()
                        let asset = AVAsset(URL: url)
                        let timescale: Double = 600
                        let time = CMTimeMake(Int64(timescale * 3.7), Int32(timescale))
                        expect(asset.duration) == time
                    } catch let error {
                        print(error)
                        expect(1) == 2
                    }
                }
            }
        }
    }
}
