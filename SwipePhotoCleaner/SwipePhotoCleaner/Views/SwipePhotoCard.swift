import Photos
import SwiftUI

struct SwipePhotoCard: View {
    let asset: SwipePhotoAsset
    let imageService: PhotoLibraryServicing
    @State private var image: UIImage?

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(.secondarySystemBackground))

                Group {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .padding(18)
                    } else {
                        Rectangle()
                            .fill(.tertiary)
                            .overlay {
                                ProgressView()
                            }
                            .padding(18)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 360)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .padding(.bottom, 16)

            VStack(alignment: .leading, spacing: 12) {
                Text(asset.asset.creationDate?.formatted(date: .abbreviated, time: .omitted) ?? "날짜 없음")
                    .font(.title3.bold())
                HStack(spacing: 12) {
                    infoChip(title: "해상도", value: "\(asset.asset.pixelWidth) × \(asset.asset.pixelHeight)")
                    infoChip(title: "유형", value: "사진")
                }

                Text("이미지는 위 전용 영역 안에서만 표시되며, 아래 안내/버튼 영역을 가리지 않습니다.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 28))
        .task(id: asset.id) {
            image = await imageService.requestImage(
                for: asset.asset,
                targetSize: CGSize(width: 1600, height: 1600)
            )
        }
    }

    private func infoChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}
