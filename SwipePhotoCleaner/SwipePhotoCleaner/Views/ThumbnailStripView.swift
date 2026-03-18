import Photos
import SwiftUI

struct ThumbnailStripView: View {
    let assets: [SwipePhotoAsset]
    let imageService: PhotoLibraryServicing

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("다음 사진")
                .font(.headline)

            if assets.isEmpty {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
                    .frame(height: 84)
                    .overlay {
                        Text("미리볼 사진이 없습니다")
                            .foregroundStyle(.secondary)
                    }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(assets) { asset in
                            ThumbnailCell(asset: asset, imageService: imageService)
                        }
                    }
                }
                .frame(height: 84)
            }
        }
    }
}

private struct ThumbnailCell: View {
    let asset: SwipePhotoAsset
    let imageService: PhotoLibraryServicing
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(.tertiary)

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ProgressView()
            }
        }
        .frame(width: 68, height: 68)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .task(id: asset.id) {
            image = await imageService.requestImage(
                for: asset.asset,
                targetSize: CGSize(width: 240, height: 240)
            )
        }
    }
}
