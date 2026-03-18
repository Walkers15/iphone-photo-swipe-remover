import SwiftUI

struct DeleteCandidateGridView: View {
    @ObservedObject var viewModel: SwipeDeckViewModel
    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("삭제 후보")
                        .font(.largeTitle.bold())
                    Text("왼쪽으로 넘긴 사진만 모아두고, 여기서 최종 삭제를 한 번만 실행합니다.")
                        .foregroundStyle(.secondary)
                }

                if viewModel.deleteCandidates.isEmpty {
                    ContentUnavailableView(
                        "삭제 후보 없음",
                        systemImage: "trash.slash",
                        description: Text("스와이프로 삭제 후보를 모으면 여기에서 작은 이미지 그리드로 볼 수 있습니다.")
                    )
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(viewModel.deleteCandidates) { asset in
                            DeleteCandidateCell(asset: asset, imageService: viewModel.service) {
                                viewModel.removeDeleteCandidate(asset)
                            }
                        }
                    }

                    Button(role: .destructive) {
                        Task {
                            await viewModel.commitDeleteCandidates()
                        }
                    } label: {
                        Label("최종 삭제 (\(viewModel.deleteCandidates.count)장)", systemImage: "trash.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .navigationTitle("삭제 후보")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DeleteCandidateCell: View {
    let asset: SwipePhotoAsset
    let imageService: PhotoLibraryServicing
    let onRemove: () -> Void
    @State private var image: UIImage?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(.tertiary)
                        .overlay { ProgressView() }
                }
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white, .black.opacity(0.6))
                    .padding(8)
            }
        }
        .task(id: asset.id) {
            image = await imageService.requestImage(
                for: asset.asset,
                targetSize: CGSize(width: 300, height: 300)
            )
        }
    }
}
