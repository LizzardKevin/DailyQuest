import SwiftUI

struct LightPromptBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.mainAccent)
            Text(message)
                .font(AppTheme.caption(13))
                .foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.inkMuted)
            }
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(AppTheme.mainAccent.opacity(0.35), lineWidth: 1)
                }
        }
        .shadow(color: AppTheme.mainAccent.opacity(0.12), radius: 12, y: 6)
    }
}
