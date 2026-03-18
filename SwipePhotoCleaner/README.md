# SwipePhotoCleaner

개인용 iPhone 사진 정리 앱의 SwiftUI MVP입니다.

## 핵심 기능
- PhotoKit으로 사용자의 사진 라이브러리를 월별 세션으로 그룹화해 로드
- 월별 세션 선택 화면에서 월 단위 정리 세션 진입
- 메인 카드에서 선택한 달의 사진만 크게 표시
- 왼쪽 스와이프: 삭제 후보 목록에 추가
- 오른쪽 스와이프: 유지
- 하단 썸네일 스트립으로 같은 달의 다음 사진 미리보기
- 삭제 후보 그리드 화면에서 작은 이미지로 후보 확인 및 개별 제거
- 최종 삭제 버튼으로 삭제 후보를 한 번에 삭제
- 드래그 중 액션 미리보기(삭제 후보/유지)와 threshold 직전 피드백
- 최근 액션 1회 실행 취소

## 구조
- `SwipePhotoCleanerApp.swift`: 앱 진입점
- `Views/`: 화면 구성 요소
- `ViewModels/SwipeDeckViewModel.swift`: 월별 세션 선택 및 스와이프/삭제 흐름 관리
- `Services/PhotoLibraryService.swift`: PhotoKit 접근, 월별 세션 그룹화, 썸네일/이미지 로드

## 주의
- 실제 삭제는 삭제 후보 화면의 최종 삭제 버튼에서만 `PHPhotoLibrary.performChanges`를 사용합니다.
- “최근 삭제된 항목” 이동은 시스템 삭제 동작을 통해 이뤄집니다.
