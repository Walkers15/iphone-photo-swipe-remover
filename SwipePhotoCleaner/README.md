# SwipePhotoCleaner

개인용 iPhone 사진 정리 앱의 SwiftUI MVP입니다.

## 핵심 기능
- PhotoKit으로 사용자의 사진 라이브러리를 날짜별 세션으로 그룹화해 로드
- 날짜 세션 선택 화면에서 하루 단위 정리 세션 진입
- 메인 카드에서 선택한 날짜의 사진만 크게 표시
- 왼쪽 스와이프: 삭제 후보를 즉시 시스템 삭제 요청으로 처리
- 오른쪽 스와이프: 유지
- 하단 썸네일 스트립으로 같은 날짜의 다음 사진 미리보기
- 최근 액션 1회 실행 취소(삭제의 경우 PhotoKit 특성상 라이브러리 복구가 아닌 UI 상태 되돌리기)

## 구조
- `SwipePhotoCleanerApp.swift`: 앱 진입점
- `Views/`: 화면 구성 요소
- `ViewModels/SwipeDeckViewModel.swift`: 날짜 세션 선택 및 스와이프/삭제 흐름 관리
- `Services/PhotoLibraryService.swift`: PhotoKit 접근, 날짜별 세션 그룹화, 썸네일/이미지 로드

## 주의
- 실제 삭제는 `PHPhotoLibrary.performChanges`를 사용하므로 iOS 권한 허용이 필요합니다.
- “최근 삭제된 항목” 이동은 시스템 삭제 동작을 통해 이뤄집니다.
