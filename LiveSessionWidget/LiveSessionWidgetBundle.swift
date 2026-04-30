//
//  LiveSessionWidgetBundle.swift
//  LiveSessionWidget
//
//  Created by Samuel Kouřil on 29.04.2026.
//

import WidgetKit
import SwiftUI

@main
struct LiveSessionWidgetBundle: WidgetBundle {
    var body: some Widget {
        LiveSessionWidget()
        LiveSessionWidgetControl()
        LiveSessionWidgetLiveActivity()
    }
}
