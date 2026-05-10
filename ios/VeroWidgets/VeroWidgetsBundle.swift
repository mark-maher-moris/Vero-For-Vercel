//
//  VeroWidgetsBundle.swift
//  VeroWidgets
//
//  Created by Mark Maher on 10/05/2026.
//

import WidgetKit
import SwiftUI

@main
struct VeroWidgetsBundle: WidgetBundle {
    var body: some Widget {
        VeroWidgets()
        VeroWidgetsControl()
        VeroWidgetsLiveActivity()
    }
}
