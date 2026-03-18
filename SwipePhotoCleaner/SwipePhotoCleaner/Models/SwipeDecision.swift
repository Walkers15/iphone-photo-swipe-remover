import Foundation

enum SwipeDecision: String {
    case keep
    case delete
}

struct SwipeAction: Identifiable {
    let id = UUID()
    let assetID: String
    let decision: SwipeDecision
    let previousIndex: Int
    let previousAssets: [SwipePhotoAsset]
    let previousDeleteCandidates: [SwipePhotoAsset]
    let sessionDate: Date
    let sessionTitle: String
}
