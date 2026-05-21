import Foundation

enum TutorialContent {
    static let overview = """
    使用指南

    1. 每日：打开 App 若今日尚未领取任务，先看「历史上的今天」，左滑进入目标录入。
    2. 领取任务：写下主线（必填）与最多两条支线，点「领取任务」由 AI 拆成 2–3 个阶段。
    3. 今日：中间 Tab 用节点进度条打卡；可连续勾选跳阶段。
    4. 日历：灰点表示有计划未完成；勋章=主线完成；镀膜=主线+全部支线完成。
    5. 修改任务：仅在「设置」中修改今日任务，会清空进度，每任务日最多 3 次（每次重新拆解）。
    6. 换日：每天凌晨 4:00（本机时区）进入新的任务日。
    7. 提醒：在设置中配置每日推送时间。
    """

    static let lightPromptDailySwipe =
        "向左滑动，进入「每日目标」并写下今日主线与支线。"
    static let lightPromptQuestPage =
        "填写主线后点「领取任务」，AI 会把每条任务拆成 2–3 个可打卡阶段。"
    static let lightPromptMainTabs =
        "底部三栏：左日历、中今日、右设置。今日是执行与打卡的主场。"
    static let lightPromptSettingsModify =
        "若要修改今日任务，请在本页「今日任务」中操作；会清空进度，每日最多 3 次。"
    static let lightPromptReminderSetup =
        "设置每天推送提醒的时间，到点会提醒你来领取今日任务。"
}
