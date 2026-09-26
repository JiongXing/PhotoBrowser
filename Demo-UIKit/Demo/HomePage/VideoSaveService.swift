import Foundation
import Photos

/// 示例共用的视频保存流程。调用方负责权限和 UI，文件所有权不依赖 Cell 生命周期。
enum VideoSaveService {
    typealias Completion = (Result<Void, Error>) -> Void
    typealias PhotoWriter = (URL, @escaping Completion) -> Void

    nonisolated static func save(from url: URL, writer: @escaping PhotoWriter = writeToPhotoLibrary, completion: @escaping Completion) {
        if url.isFileURL {
            // 本地源文件属于调用方，保存流程不删除它。
            writer(url, completion)
            return
        }

        URLSession.shared.downloadTask(with: url) { location, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let location = location else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            // 必须在 URLSession 回调返回前移动文件；回调返回后系统可删除 location。
            saveDownloadedVideo(at: location, writer: writer, completion: completion)
        }.resume()
    }

    nonisolated static func saveDownloadedVideo(at location: URL, writer: @escaping PhotoWriter = writeToPhotoLibrary, completion: @escaping Completion) {
        let ownedURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")
        do {
            try FileManager.default.moveItem(at: location, to: ownedURL)
        } catch {
            completion(.failure(error))
            return
        }

        writer(ownedURL) { result in
            // 只清理本次下载产生的副本；不依赖 UI 对象仍存活。
            try? FileManager.default.removeItem(at: ownedURL)
            completion(result)
        }
    }

    nonisolated private static func writeToPhotoLibrary(_ url: URL, completion: @escaping Completion) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) { success, error in
            if success {
                completion(.success(()))
            } else {
                let error = error ?? NSError(domain: "VideoSaveService", code: 1,
                                             userInfo: [NSLocalizedDescriptionKey: "无法保存视频"])
                completion(.failure(error))
            }
        }
    }
}
