import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SwipeDeckViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.authorizationState {
                case .authorized:
                    if let session = viewModel.selectedSession {
                        SwipeDeckView(viewModel: viewModel, session: session)
                    } else {
                        SessionListView(viewModel: viewModel)
                    }
                case .loading:
                    ProgressView("사진을 불러오는 중…")
                        .task {
                            await viewModel.loadIfNeeded()
                        }
                case .denied:
                    PermissionDeniedView()
                }
            }
            .navigationTitle(viewModel.selectedSession == nil ? "날짜별 세션" : "사진 정리")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if viewModel.hasSessionSelected {
                        Button("세션") {
                            viewModel.clearSessionSelection()
                        }
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    if viewModel.authorizationState == .authorized {
                        if viewModel.hasSessionSelected {
                            NavigationLink {
                                DeleteCandidateGridView(viewModel: viewModel)
                            } label: {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: "square.grid.2x2")

                                    if !viewModel.deleteCandidates.isEmpty {
                                        Text(viewModel.deleteCandidateCountText)
                                            .font(.caption2.bold())
                                            .padding(4)
                                            .background(.red, in: Circle())
                                            .foregroundStyle(.white)
                                            .offset(x: 10, y: -10)
                                    }
                                }
                            }
                        }

                        Button {
                            Task {
                                await viewModel.reload()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.requestAccessIfNeeded()
        }
    }
}

#Preview {
    ContentView()
}
