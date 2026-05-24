import SwiftData
import Foundation

enum ModelContainerFactory {
  static let schema = Schema([
    DailyPlan.self,
    TaskItem.self,
    TaskStage.self,
    DailyMedal.self,
  ])

  static func make() -> ModelContainer {
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    do {
      return try ModelContainer(for: schema, configurations: [configuration])
    } catch {
      // 模型变更后旧库不兼容时，删除本地 store 再试一次。
      let url = configuration.url
      try? FileManager.default.removeItem(at: url)
      try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + "-wal"))
      try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + "-shm"))
      do {
        return try ModelContainer(for: schema, configurations: [configuration])
      } catch {
        fatalError("DailyQuest ModelContainer failed: \(error)")
      }
    }
  }
}
