//
//  TaskCheckerWidgetLiveActivity.swift
//  TaskCheckerWidget
//
//  Created by Lev Vlasov on 2025-05-01.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct TaskCheckerWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct TaskCheckerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TaskCheckerWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension TaskCheckerWidgetAttributes {
    fileprivate static var preview: TaskCheckerWidgetAttributes {
        TaskCheckerWidgetAttributes(name: "World")
    }
}

extension TaskCheckerWidgetAttributes.ContentState {
    fileprivate static var smiley: TaskCheckerWidgetAttributes.ContentState {
        TaskCheckerWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: TaskCheckerWidgetAttributes.ContentState {
         TaskCheckerWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: TaskCheckerWidgetAttributes.preview) {
   TaskCheckerWidgetLiveActivity()
} contentStates: {
    TaskCheckerWidgetAttributes.ContentState.smiley
    TaskCheckerWidgetAttributes.ContentState.starEyes
}
