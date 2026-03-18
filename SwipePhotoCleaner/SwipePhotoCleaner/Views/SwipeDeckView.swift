import SwiftUI
import UIKit

struct SwipeDeckView: View {
    private enum SwipePreviewState: Equatable {
        case neutral
        case deleteHint
        case deleteCommit
        case keepHint
        case keepCommit

        var isDelete: Bool {
            self == .deleteHint || self == .deleteCommit
        }

        var isKeep: Bool {
            self == .keepHint || self == .keepCommit
        }

        var title: String {
            switch self {
            case .neutral:
                return "← 삭제 후보 / 유지 →"
            case .deleteHint:
                return "삭제 후보"
            case .deleteCommit:
                return "놓으면 삭제 후보 추가"
            case .keepHint:
                return "유지"
            case .keepCommit:
                return "놓으면 유지"
            }
        }

        var subtitle: String {
            switch self {
            case .neutral:
                return "카드를 넘기기 전에 미리 결과를 확인할 수 있어요"
            case .deleteHint:
                return "이 방향으로 놓으면 삭제 후보에 담깁니다"
            case .deleteCommit:
                return "손을 떼면 삭제 후보 목록으로 들어갑니다"
            case .keepHint:
                return "이 방향으로 놓으면 유지됩니다"
            case .keepCommit:
                return "손을 떼면 유지로 확정됩니다"
            }
        }

        var icon: String {
            switch self {
            case .neutral:
                return "hand.draw"
            case .deleteHint, .deleteCommit:
                return "trash"
            case .keepHint, .keepCommit:
                return "checkmark"
            }
        }

        var color: Color {
            switch self {
            case .neutral:
                return .secondary
            case .deleteHint, .deleteCommit:
                return .red
            case .keepHint, .keepCommit:
                return .green
            }
        }
    }

    @ObservedObject var viewModel: SwipeDeckViewModel
    let session: PhotoMonthSession
    @State private var dragOffset: CGSize = .zero
    @State private var lastHapticState: SwipePreviewState = .neutral

    private let previewThreshold: CGFloat = 44
    private let commitThreshold: CGFloat = 120

    var body: some View {
        VStack(spacing: 20) {
            header

            ZStack {
                actionSurface

                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(.secondarySystemBackground))
                    .overlay {
                        if let asset = viewModel.currentAsset {
                            SwipePhotoCard(asset: asset, imageService: viewModel.service)
                        } else {
                            ContentUnavailableView(
                                "세션 완료",
                                systemImage: "checkmark.circle",
                                description: Text("이 달의 사진을 모두 검토했습니다.")
                            )
                        }
                    }
                    .overlay(alignment: .topLeading) {
                        swipeBadge(title: swipePreviewState.isDelete ? swipePreviewState.title : "삭제 후보", color: .red)
                            .opacity(deleteBadgeOpacity)
                    }
                    .overlay(alignment: .topTrailing) {
                        swipeBadge(title: swipePreviewState.isKeep ? swipePreviewState.title : "유지", color: .green)
                            .opacity(keepBadgeOpacity)
                    }
                    .overlay {
                        swipePreviewOverlay
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

    private var swipePreviewState: SwipePreviewState {
        let width = dragOffset.width

        if width <= -commitThreshold { return .deleteCommit }
        if width < -previewThreshold { return .deleteHint }
        if width >= commitThreshold { return .keepCommit }
        if width > previewThreshold { return .keepHint }
        return .neutral
    }


    private var deleteBadgeOpacity: Double {
        min(max(Double(-dragOffset.width / 70), 0), 1)
    }

    private var keepBadgeOpacity: Double {
        min(max(Double(dragOffset.width / 70), 0), 1)
    }

    private var actionSurface: some View {
        RoundedRectangle(cornerRadius: 28)
            .fill(surfaceBackgroundColor)
            .overlay(alignment: swipePreviewState.isDelete ? .leading : .trailing) {
                HStack(spacing: 14) {
                    if swipePreviewState.isDelete {
                        actionSurfaceContent
                        Spacer(minLength: 0)
                    } else if swipePreviewState.isKeep {
                        Spacer(minLength: 0)
                        actionSurfaceContent
                    }
                }
                .padding(.horizontal, 22)
            }
            .scaleEffect(swipePreviewState == .neutral ? 0.98 : 1)
            .opacity(swipePreviewState == .neutral ? 0.35 : 1)
    }

    private var actionSurfaceContent: some View {
        VStack(alignment: swipePreviewState.isDelete ? .leading : .trailing, spacing: 12) {
            Image(systemName: swipePreviewState.icon)
                .font(.title.weight(.bold))
                .foregroundStyle(swipePreviewState.color)
                .frame(width: 58, height: 58)
                .background(.white.opacity(0.92), in: Circle())
                .scaleEffect(swipePreviewState == .deleteCommit || swipePreviewState == .keepCommit ? 1.08 : 1)

            VStack(alignment: swipePreviewState.isDelete ? .leading : .trailing, spacing: 4) {
                Text(swipePreviewState.title)
                    .font(.title2.bold())
                Text(swipePreviewState.subtitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.88))
            }
            .foregroundStyle(.white)
        }
        .frame(maxWidth: 220)
        .opacity(swipePreviewState == .neutral ? 0 : 1)
    }

    private var swipePreviewOverlay: some View {
        VStack {
            Spacer()

            VStack(spacing: 6) {
                Text(swipePreviewState.title)
                    .font(.headline.bold())
                Text(swipePreviewState.subtitle)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(swipePreviewState.color.opacity(swipePreviewState == .neutral ? 0.12 : 0.4), lineWidth: 1)
            }
            .foregroundStyle(swipePreviewState == .neutral ? .primary : swipePreviewState.color)
            .padding(.bottom, 26)
            .opacity(swipePreviewState == .neutral ? 0.82 : 1)
            .scaleEffect(swipePreviewState == .deleteCommit || swipePreviewState == .keepCommit ? 1.04 : 1)
        }
        .padding(20)
        .allowsHitTesting(false)
    }

    private var surfaceBackgroundColor: Color {
        switch swipePreviewState {
        case .neutral:
            return Color(.systemGray5)
        case .deleteHint:
            return .red.opacity(0.32)
        case .deleteCommit:
            return .red.opacity(0.58)
        case .keepHint:
            return .green.opacity(0.32)
        case .keepCommit:
            return .green.opacity(0.58)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.title)
                    .font(.title2.bold())
                Text(swipePreviewState.title)
                    .foregroundStyle(swipePreviewState.color)
                    .animation(.easeInOut(duration: 0.15), value: swipePreviewState)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Label("삭제 후보 \(viewModel.deleteCandidateCountText)", systemImage: "trash")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.red.opacity(0.12), in: Capsule())
                    .foregroundStyle(.red)

                Text(viewModel.progressText)
                    .font(.headline.monospacedDigit())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.thinMaterial, in: Capsule())
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 16) {
            actionButton(title: "삭제 후보", systemImage: "trash", tint: .red, isActive: swipePreviewState.isDelete) {
                triggerSwipe(.delete)
            }

            actionButton(title: "유지", systemImage: "heart", tint: .green, isActive: swipePreviewState.isKeep) {
                triggerSwipe(.keep)
            }
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

    private func actionButton(title: String, systemImage: String, tint: Color, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity)
                .font(.headline)
        }
        .buttonStyle(.borderedProminent)
        .tint(tint)
        .scaleEffect(isActive ? 1.03 : 1)
        .shadow(color: tint.opacity(isActive ? 0.25 : 0), radius: 14, y: 6)
        .opacity(buttonOpacity(isActive: isActive))
        .disabled(viewModel.currentAsset == nil)
    }

    private func buttonOpacity(isActive: Bool) -> Double {
        switch swipePreviewState {
        case .neutral:
            return 1
        default:
            return isActive ? 1 : 0.72
        }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
                handleHapticIfNeeded(for: swipePreviewState)
            }
            .onEnded { value in
                if value.translation.width < -commitThreshold {
                    triggerSwipe(.delete)
                } else if value.translation.width > commitThreshold {
                    triggerSwipe(.keep)
                } else {
                    dragOffset = .zero
                    lastHapticState = .neutral
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
            lastHapticState = .neutral
        }
    }

    private func handleHapticIfNeeded(for state: SwipePreviewState) {
        guard state != lastHapticState else { return }

        if state == .deleteCommit || state == .keepCommit {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }

        lastHapticState = state
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
