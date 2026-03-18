import Photos
import SwiftUI

protocol PhotoLibraryServicing {
    func requestAuthorization() async -> PHAuthorizationStatus
    func fetchMonthSessions() async -> [PhotoMonthSession]
    func requestImage(for asset: PHAsset, targetSize: CGSize) async -> UIImage?
    func delete(assets: [PHAsset]) async throws
}

enum PhotoLibraryError: Error {
    case deletionFailed
}

final class PhotoLibraryService: PhotoLibraryServicing {
    private let imageManager = PHCachingImageManager()
    private let calendar = Calendar.current
    private let titleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"
        return formatter
    }()

    func requestAuthorization() async -> PHAuthorizationStatus {
        await withCheckedContinuation { (continuation: CheckedContinuation<PHAuthorizationStatus, Never>) in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                continuation.resume(returning: status)
            }
        }
    }

    func fetchMonthSessions() async -> [PhotoMonthSession] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

        let result = PHAsset.fetchAssets(with: options)
        var grouped: [Date: [SwipePhotoAsset]] = [:]

        result.enumerateObjects { asset, _, _ in
            let creationDate = asset.creationDate ?? .distantPast
            let components = self.calendar.dateComponents([.year, .month], from: creationDate)
            let month = self.calendar.date(from: components) ?? creationDate
            grouped[month, default: []].append(SwipePhotoAsset(asset: asset))
        }

        return grouped.keys.sorted(by: >).map { month in
            let assets = grouped[month, default: []]
            return PhotoMonthSession(
                date: month,
                title: self.titleFormatter.string(from: month),
                subtitle: "사진 \(assets.count)장",
                assets: assets
            )
        }
    }

    func requestImage(for asset: PHAsset, targetSize: CGSize) async -> UIImage? {
        await withCheckedContinuation { (continuation: CheckedContinuation<UIImage?, Never>) in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = true

            self.imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }

    func delete(assets: [PHAsset]) async throws {
        guard !assets.isEmpty else { return }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(assets as NSArray)
            }, completionHandler: { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: PhotoLibraryError.deletionFailed)
                }
            })
        }
    }
}
