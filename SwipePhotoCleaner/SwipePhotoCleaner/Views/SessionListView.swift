import SwiftUI

struct SessionListView: View {
    @ObservedObject var viewModel: SwipeDeckViewModel

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("월별 세션으로 정리")
                        .font(.headline)
                    Text("한 번에 한 달치 사진만 묶어서 검토할 수 있습니다.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }

            if viewModel.sessions.isEmpty {
                ContentUnavailableView(
                    "사진 없음",
                    systemImage: "photo.on.rectangle.angled",
                    description: Text("사진 라이브러리에서 표시할 이미지가 없습니다.")
                )
            } else {
                Section("세션 선택") {
                    ForEach(viewModel.sessions) { session in
                        Button {
                            viewModel.selectSession(session)
                        } label: {
                            HStack(spacing: 14) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(session.title)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(session.subtitle)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}
