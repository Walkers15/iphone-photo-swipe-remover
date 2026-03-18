import Foundation

struct PhotoMonthSession: Identifiable, Equatable {
    let date: Date
    let title: String
    let subtitle: String
    let assets: [SwipePhotoAsset]

    var id: Date { date }
    var assetCount: Int { assets.count }
}
