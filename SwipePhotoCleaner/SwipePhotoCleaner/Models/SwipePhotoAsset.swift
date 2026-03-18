import Foundation
import Photos

struct SwipePhotoAsset: Identifiable, Equatable {
    let id: String
    let asset: PHAsset

    init(asset: PHAsset) {
        self.id = asset.localIdentifier
        self.asset = asset
    }
}
