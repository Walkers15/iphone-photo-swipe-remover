import Foundation

struct PhotoDaySession: Identifiable, Equatable {
    let date: Date
    let title: String
    let subtitle: String
    let assets: [SwipePhotoAsset]

    var id: Date { date }
    var assetCount: Int { assets.count }
}
