import SwiftUI

struct PermissionDeniedView: View {
    var body: some View {
        ContentUnavailableView {
            Label("사진 접근 권한 필요", systemImage: "photo.badge.exclamationmark")
        } description: {
            Text("설정에서 사진 접근을 허용하면 정리를 시작할 수 있습니다.")
        } actions: {
            Text("설정 > 개인정보 보호 및 보안 > 사진")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
