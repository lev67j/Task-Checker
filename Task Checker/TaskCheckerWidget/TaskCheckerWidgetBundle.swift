//
//  TaskCheckerWidgetBundle.swift
//  TaskCheckerWidget
//
//  Created by Lev Vlasov on 2025-05-01.
//

import WidgetKit
import SwiftUI

@main
struct TaskCheckerWidgetBundle: WidgetBundle {
    var body: some Widget {
        TaskCheckerWidget()
        TaskCheckerWidgetControl()
        TaskCheckerWidgetLiveActivity()
    }
}
