import WidgetKit
import SwiftUI

@main
struct VeroWidgetBundle: WidgetBundle {
    var body: some Widget {
        UsersSmallWidget()
        LogsMediumWidget()
        LogsLargeWidget()
        AnalyticsLargeWidget()
        CountriesMediumWidget()
    }
}
