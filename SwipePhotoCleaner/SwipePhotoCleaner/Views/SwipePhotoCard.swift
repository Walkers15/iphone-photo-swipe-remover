import Photos
import SwiftUI

struct SwipePhotoCard: View {
    let asset: SwipePhotoAsset
    let imageService: PhotoLibraryServicing
    @State private var image: UIImage?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(.tertiary)
                        .overlay {
                            ProgressView()
                        }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 28))

            LinearGradient(
                colors: [.clear, .black.opacity(0.65)],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 28))

            VStack(alignment: .leading, spacing: 6) {
                Text(asset.asset.creationDate?.formatted(date: .abbreviated, time: .omitted) ?? "날짜 없음")
                    .font(.headline)
                Text("\(asset.asset.pixelWidth) × \(asset.asset.pixelHeight)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .foregroundStyle(.white)
            .padding(24)
        }
        .task(id: asset.id) {
            image = await imageService.requestImage(
                for: asset.asset,
                targetSize: CGSize(width: 1600, height: 1600)
            )
        }
    }
}
