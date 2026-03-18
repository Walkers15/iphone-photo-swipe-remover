import Photos
import SwiftUI

protocol PhotoLibraryServicing {
    func requestAuthorization() async -> PHAuthorizationStatus
    func fetchDaySessions() async -> [PhotoDaySession]
    func requestImage(for asset: PHAsset, targetSize: CGSize) async -> UIImage?
    func delete(asset: PHAsset) async throws
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
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    func requestAuthorization() async -> PHAuthorizationStatus {
        await withCheckedContinuation { (continuation: CheckedContinuation<PHAuthorizationStatus, Never>) in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                continuation.resume(returning: status)
            }
        }
    }

    func fetchDaySessions() async -> [PhotoDaySession] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

        let result = PHAsset.fetchAssets(with: options)
        var grouped: [Date: [SwipePhotoAsset]] = [:]

        result.enumerateObjects { asset, _, _ in
            let creationDate = asset.creationDate ?? .distantPast
            let day = self.calendar.startOfDay(for: creationDate)
            grouped[day, default: []].append(SwipePhotoAsset(asset: asset))
        }

        return grouped.keys.sorted(by: >).map { day in
            let assets = grouped[day, default: []]
            return PhotoDaySession(
                date: day,
                title: self.titleFormatter.string(from: day),
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

    func delete(asset: PHAsset) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets([asset] as NSArray)
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
