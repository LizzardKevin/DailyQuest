import SwiftUI

/// 带节点的阶段进度条；旁侧展示当前阶段文案。
struct StageProgressBar: View {
    let stages: [TaskStage]
    let accent: Color
    var compact: Bool = false
    let onToggle: (TaskStage) -> Void

    private var sortedStages: [TaskStage] {
        stages.sorted { $0.order < $1.order }
    }

    private var currentStage: TaskStage? {
        sortedStages.first { !$0.isDone } ?? sortedStages.last
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 10 : 14) {
            progressTrack

            if let current = currentStage {
                VStack(alignment: .leading, spacing: 4) {
                    Text(current.isDone && sortedStages.allSatisfy(\.isDone) ? "已全部完成" : "当前阶段")
                        .font(AppTheme.caption(compact ? 11 : 12))
                        .foregroundStyle(AppTheme.inkMuted)
                    Text(current.title)
                        .font(AppTheme.body(compact ? 14 : 15))
                        .foregroundStyle(AppTheme.ink)
                    if let hint = current.hint, !hint.isEmpty, !current.isDone {
                        Text(hint)
                            .font(AppTheme.caption(12))
                            .foregroundStyle(AppTheme.inkMuted)
                    }
                }
            }
        }
    }

    private var progressTrack: some View {
        HStack(spacing: 0) {
            ForEach(Array(sortedStages.enumerated()), id: \.element.persistentModelID) { index, stage in
                nodeButton(stage: stage, isCurrent: stage.persistentModelID == currentStage?.persistentModelID)
                if index < sortedStages.count - 1 {
                    connector(from: stage, to: sortedStages[index + 1])
                }
            }
        }
    }

    @ViewBuilder
    private func connector(from: TaskStage, to: TaskStage) -> some View {
        Rectangle()
            .fill(from.isDone ? accent : Color.white.opacity(0.35))
            .frame(height: compact ? 3 : 4)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 2)
    }

    private func nodeButton(stage: TaskStage, isCurrent: Bool) -> some View {
        Button {
            onToggle(stage)
        } label: {
            ZStack {
                if stage.isDone {
                    Circle()
                        .fill(accent)
                        .frame(width: compact ? 22 : 28, height: compact ? 22 : 28)
                    Image(systemName: "checkmark")
                        .font(.system(size: compact ? 10 : 12, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: compact ? 22 : 28, height: compact ? 22 : 28)
                        .overlay {
                            Circle()
                                .strokeBorder(isCurrent ? accent : AppTheme.glassEdge, lineWidth: isCurrent ? 2 : 1.2)
                        }
                }
            }
        }
        .buttonStyle(.plain)
    }
}
