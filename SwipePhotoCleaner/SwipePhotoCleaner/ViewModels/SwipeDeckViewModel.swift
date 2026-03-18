import Foundation
import Photos
import SwiftUI

@MainActor
final class SwipeDeckViewModel: ObservableObject {
    enum AuthorizationState {
        case loading
        case authorized
        case denied
    }

    @Published private(set) var authorizationState: AuthorizationState = .loading
    @Published private(set) var sessions: [PhotoMonthSession] = []
    @Published private(set) var selectedSession: PhotoMonthSession?
    @Published private(set) var currentIndex = 0
    @Published private(set) var deleteCandidates: [SwipePhotoAsset] = []
    @Published private(set) var lastAction: SwipeAction?
    @Published var errorMessage: String?

    let service: PhotoLibraryServicing
    private var hasLoaded = false

    init(service: PhotoLibraryServicing = PhotoLibraryService()) {
        self.service = service
    }

    var currentAsset: SwipePhotoAsset? {
        guard let selectedSession, selectedSession.assets.indices.contains(currentIndex) else { return nil }
        return selectedSession.assets[currentIndex]
    }

    var upcomingAssets: [SwipePhotoAsset] {
        guard let selectedSession else { return [] }
        let assets = selectedSession.assets
        let start = min(currentIndex + 1, assets.count)
        let end = min(start + 5, assets.count)
        return Array(assets[start..<end])
    }

    var progressText: String {
        guard let selectedSession else { return "세션 선택" }
        guard !selectedSession.assets.isEmpty, currentIndex < selectedSession.assets.count else { return "완료" }
        return "\(currentIndex + 1) / \(selectedSession.assets.count)"
    }

    var hasSessionSelected: Bool {
        selectedSession != nil
    }

    var deleteCandidateCountText: String {
        "\(deleteCandidates.count)"
    }

    func requestAccessIfNeeded() async {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            authorizationState = .authorized
            await loadIfNeeded()
        case .notDetermined:
            authorizationState = .loading
            let updated = await service.requestAuthorization()
            if updated == .authorized || updated == .limited {
                authorizationState = .authorized
                await loadIfNeeded()
            } else {
                authorizationState = .denied
            }
        default:
            authorizationState = .denied
        }
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await reload()
    }

    func reload() async {
        authorizationState = .loading
        let selectedDate = selectedSession?.date
        sessions = await service.fetchMonthSessions()
        selectedSession = sessions.first(where: { $0.date == selectedDate })
        currentIndex = 0
        lastAction = nil
        errorMessage = nil
        hasLoaded = true
        authorizationState = .authorized
    }

    func selectSession(_ session: PhotoMonthSession) {
        selectedSession = session
        currentIndex = 0
        lastAction = nil
        errorMessage = nil
    }

    func clearSessionSelection() {
        selectedSession = nil
        currentIndex = 0
        lastAction = nil
    }

    func handleSwipe(_ decision: SwipeDecision) async {
        guard let currentAsset, let selectedSession else { return }
        let action = SwipeAction(
            assetID: currentAsset.id,
            decision: decision,
            previousIndex: currentIndex,
            previousAssets: selectedSession.assets,
            previousDeleteCandidates: deleteCandidates,
            sessionDate: selectedSession.date,
            sessionTitle: selectedSession.title
        )

        if decision == .delete, !deleteCandidates.contains(currentAsset) {
            deleteCandidates.append(currentAsset)
        }

        let updatedAssets = selectedSession.assets.filter { $0.id != currentAsset.id }
        updateSelectedSessionAssets(updatedAssets)
        lastAction = action

        if currentIndex >= updatedAssets.count {
            currentIndex = updatedAssets.isEmpty ? 0 : updatedAssets.count - 1
        }
    }

    func undoLastAction() {
        guard let lastAction else { return }

        let restoredSession = PhotoMonthSession(
            date: lastAction.sessionDate,
            title: lastAction.sessionTitle,
            subtitle: "사진 \(lastAction.previousAssets.count)장",
            assets: lastAction.previousAssets
        )

        self.selectedSession = restoredSession
        self.deleteCandidates = lastAction.previousDeleteCandidates
        if let index = sessions.firstIndex(where: { $0.date == restoredSession.date }) {
            sessions[index] = restoredSession
        } else {
            sessions.append(restoredSession)
            sessions.sort { $0.date > $1.date }
        }
        currentIndex = min(lastAction.previousIndex, max(restoredSession.assets.count - 1, 0))
        self.lastAction = nil
    }

    func removeDeleteCandidate(_ asset: SwipePhotoAsset) {
        deleteCandidates.removeAll { $0.id == asset.id }
    }

    func commitDeleteCandidates() async {
        let assetsToDelete = deleteCandidates.map(\.asset)

        do {
            try await service.delete(assets: assetsToDelete)
            deleteCandidates.removeAll()
            lastAction = nil
            await reload()
        } catch {
            errorMessage = "삭제 후보 사진을 삭제하지 못했습니다. 다시 시도해주세요."
        }
    }

    private func updateSelectedSessionAssets(_ assets: [SwipePhotoAsset]) {
        guard let selectedSession else { return }

        let updatedSession = PhotoMonthSession(
            date: selectedSession.date,
            title: selectedSession.title,
            subtitle: "사진 \(assets.count)장",
            assets: assets
        )

        self.selectedSession = updatedSession

        if let index = sessions.firstIndex(where: { $0.date == selectedSession.date }) {
            if assets.isEmpty {
                sessions.remove(at: index)
                self.selectedSession = nil
            } else {
                sessions[index] = updatedSession
            }
        }
    }
}
