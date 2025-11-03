//
//  TalkExampleApp.swift
//  TalkExample
//
//  Created by 佐藤汰一 on 2025/10/31.
//

import SwiftUI

@main
struct TalkExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.voiceChatManager, VoiceChatManager())
        }
    }
}
