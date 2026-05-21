import SwiftUI

struct OnboardingReminderView: View {
    let onComplete: () -> Void

    @State private var selectedTime = Calendar.current.date(
        from: DateComponents(hour: 8, minute: 0)
    ) ?? .now
    @State private var errorMessage: String?
    @State private var isSaving = false
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 48)

            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 88, height: 88)
                        .overlay {
                            Circle().strokeBorder(AppTheme.glassBorder, lineWidth: 1.2)
                        }
                    Image(systemName: "sun.horizon.fill")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(AppTheme.mainGradient)
                }
                .scaleEffect(appeared ? 1 : 0.6)
                .opacity(appeared ? 1 : 0)

                ScreenHeader(
                    "每日任务",
                    subtitle: "每天早上，用一条主线开启这一天"
                )
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal, 28)

            GlassCard {
                VStack(spacing: 16) {
                    Text("选择提醒时间")
                        .font(AppTheme.caption())
                        .foregroundStyle(AppTheme.inkMuted)

                    DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()

                    if let errorMessage {
                        Text(errorMessage)
                            .font(AppTheme.caption(12))
                            .foregroundStyle(.red)
                    }

                    PrimaryButton("开启清晨提醒", icon: "bell.badge") {
                        Task { await saveAndContinue() }
                    }
                    .disabled(isSaving)
                    .overlay {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .offset(y: appeared ? 0 : 24)
            .opacity(appeared ? 1 : 0)

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    private func saveAndContinue() async {
        isSaving = true
        defer { isSaving = false }

        let components = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
        let hour = components.hour ?? 8
        let minute = components.minute ?? 0

        ReminderSettings.save(hour: hour, minute: minute)

        do {
            try await NotificationService.shared.scheduleDailyReminder(hour: hour, minute: minute)
            onComplete()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

