import XCTest
import AVFoundation
import Photos
@testable import RotationHost

final class VideoSaveTests: XCTestCase {
    func testDownloadedFileSurvivesCallbackAndIsCleanedOnSuccessOrFailure() throws {
        for succeeds in [true, false] {
            let source = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            let bytes = Data("downloaded video".utf8)
            try bytes.write(to: source)
            var ownedURL: URL!
            var finish: VideoSaveService.Completion!
            let completed = expectation(description: "save completed")
            VideoSaveService.saveDownloadedVideo(at: source, writer: { url, completion in
                ownedURL = url
                finish = completion
            }) { result in
                switch result {
                case .success: XCTAssertTrue(succeeds)
                case .failure: XCTAssertFalse(succeeds)
                }
                XCTAssertFalse(FileManager.default.fileExists(atPath: ownedURL.path))
                completed.fulfill()
            }
            // 模拟下载回调返回，URLSession 不再为原路径保留文件。
            XCTAssertFalse(FileManager.default.fileExists(atPath: source.path))
            XCTAssertNotEqual(source, ownedURL)
            XCTAssertEqual(try Data(contentsOf: ownedURL), bytes)
            finish(succeeds ? .success(()) : .failure(URLError(.cannotWriteToFile)))
            wait(for: [completed], timeout: 3)
        }
    }

    func testCallerOwnedLocalTemporaryFileIsNeverDeleted() throws {
        let source = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
        let bytes = Data("local video".utf8)
        try bytes.write(to: source)
        defer { try? FileManager.default.removeItem(at: source) }
        for succeeds in [true, false] {
            let completed = expectation(description: "local save completed")
            VideoSaveService.save(from: source, writer: { url, completion in
                XCTAssertEqual(url, source)
                completion(succeeds ? .success(()) : .failure(URLError(.cannotWriteToFile)))
            }) { _ in completed.fulfill() }
            wait(for: [completed], timeout: 3)
            XCTAssertEqual(try Data(contentsOf: source), bytes)
        }
    }

    func testMissingDownloadFailsBeforePhotoWrite() {
        let completed = expectation(description: "missing file")
        VideoSaveService.saveDownloadedVideo(at: URL(fileURLWithPath: "/missing/\(UUID().uuidString)"), writer: { _, _ in
            XCTFail("Photo writer must not receive a missing file")
        }) { result in
            if case .success = result { XCTFail("Missing file must fail") }
            completed.fulfill()
        }
        wait(for: [completed], timeout: 3)
    }
}

@MainActor
final class VideoSaveSmokeTests: XCTestCase {
    func testSaveGeneratedVideoToPhotoLibrary() throws {
        XCTAssertEqual(PHPhotoLibrary.authorizationStatus(for: .addOnly), .authorized,
                       "Grant photos-add to com.jxphotobrowser.RotationHost before running the smoke test")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
        defer { try? FileManager.default.removeItem(at: url) }
        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: 32, AVVideoHeightKey: 32
        ])
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: 32, kCVPixelBufferHeightKey as String: 32
        ])
        writer.add(input)
        XCTAssertTrue(writer.startWriting())
        writer.startSession(atSourceTime: .zero)
        var buffer: CVPixelBuffer?
        XCTAssertEqual(CVPixelBufferCreate(kCFAllocatorDefault, 32, 32, kCVPixelFormatType_32ARGB, nil, &buffer), kCVReturnSuccess)
        let pixels = try XCTUnwrap(buffer)
        CVPixelBufferLockBaseAddress(pixels, [])
        memset(try XCTUnwrap(CVPixelBufferGetBaseAddress(pixels)), 0, CVPixelBufferGetDataSize(pixels))
        CVPixelBufferUnlockBaseAddress(pixels, [])
        XCTAssertTrue(adaptor.append(pixels, withPresentationTime: .zero))
        XCTAssertTrue(adaptor.append(pixels, withPresentationTime: CMTime(value: 1, timescale: 1)))
        input.markAsFinished()
        let generated = expectation(description: "video generated")
        writer.finishWriting { generated.fulfill() }
        wait(for: [generated], timeout: 10)
        XCTAssertEqual(writer.status, .completed, "\(String(describing: writer.error))")

        let saved = expectation(description: "video saved to Photos")
        VideoSaveService.save(from: url) { result in
            if case .failure(let error) = result { XCTFail("Photos save failed: \(error)") }
            saved.fulfill()
        }
        wait(for: [saved], timeout: 20)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }
}
