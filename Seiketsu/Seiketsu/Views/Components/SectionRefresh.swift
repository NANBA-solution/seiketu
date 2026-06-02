import SwiftUI

extension View {
    /// プルダウンでのみ更新（ナビバーの更新アイコンは付けない）
    func sectionReloadable(action: @escaping () async -> Void) -> some View {
        refreshable {
            await action()
        }
    }
}
