import WidgetKit
import SwiftUI

@main
struct DailyArcWidgetBundle: WidgetBundle {
    var body: some Widget {
        SmallStreakWidget()
        MediumTodayWidget()
        LargeStatsWidget()
    }
}
