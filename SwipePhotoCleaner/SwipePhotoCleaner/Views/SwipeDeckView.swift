import SwiftUI

struct SwipeDeckView: View {
    @ObservedObject var viewModel: SwipeDeckViewModel
    let session: PhotoDaySession
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        VStack(spacing: 20) {
            header

            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(.secondarySystemBackground))
                    .overlay {
                        if let asset = viewModel.currentAsset {
                            SwipePhotoCard(asset: asset, imageService: viewModel.service)
                        } else {
                            ContentUnavailableView(
                                "세션 완료",
                                systemImage: "checkmark.circle",
                                description: Text("이 날짜의 사진을 모두 검토했습니다.")
                            )
                        }
                    }
                    .overlay(alignment: .topLeading) {
                        swipeBadge(title: "삭제", color: .red)
                            .opacity(max(0, -dragOffset.width / 80))
                    }
                    .overlay(alignment: .topTrailing) {
                        swipeBadge(title: "유지", color: .green)
                            .opacity(max(0, dragOffset.width / 80))
                    }
                    .offset(x: dragOffset.width)
                    .rotationEffect(.degrees(Double(dragOffset.width / 20)))
                    .gesture(dragGesture)
                    .animation(.spring(response: 0.28, dampingFraction: 0.82), value: dragOffset)
            }
            .frame(maxHeight: .infinity)

            ThumbnailStripView(assets: viewModel.upcomingAssets, imageService: viewModel.service)

            actionButtons
        }
        .padding()
        .alert("안내", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { newValue in if !newValue { viewModel.errorMessage = nil } }
        )) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.title)
                    .font(.title2.bold())
                Text("같은 날짜 사진만 정리 중 · 왼쪽은 삭제, 오른쪽은 유지")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(viewModel.progressText)
                .font(.headline.monospacedDigit())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.thinMaterial, in: Capsule())
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button {
                triggerSwipe(.delete)
            } label: {
                Label("삭제", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(viewModel.currentAsset == nil)

            Button {
                triggerSwipe(.keep)
            } label: {
                Label("유지", systemImage: "heart")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(viewModel.currentAsset == nil)
        }
        .overlay(alignment: .topTrailing) {
            if viewModel.lastAction != nil {
                Button("실행 취소") {
                    viewModel.undoLastAction()
                }
                .padding(.top, -44)
            }
        }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                if value.translation.width < -120 {
                    triggerSwipe(.delete)
                } else if value.translation.width > 120 {
                    triggerSwipe(.keep)
                } else {
                    dragOffset = .zero
                }
            }
    }

    private func triggerSwipe(_ decision: SwipeDecision) {
        let targetX: CGFloat = decision == .delete ? -500 : 500
        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
            dragOffset = CGSize(width: targetX, height: 0)
        }

        Task {
            try? await Task.sleep(for: .milliseconds(120))
            await viewModel.handleSwipe(decision)
            dragOffset = .zero
        }
    }

    private func swipeBadge(title: String, color: Color) -> some View {
        Text(title)
            .font(.headline.bold())
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
            .padding()
    }
}
