//
//  VoiceChatManagement.swift
//  TalkExample
//
//  Created by 佐藤汰一 on 2025/11/03.
//

import SwiftUI

protocol VoiceChatManagement {
    @MainActor
    func requestPermission() async throws
    func startRecording() throws -> AsyncThrowingStream<VoiceChatResponse, Error>
    func stopRecording()
    func prewarm() throws
    func speak(_ message: String)
}

extension EnvironmentValues {
    @Entry var voiceChatManager: VoiceChatManagement = MockVoiceChatManagement()
}

final class MockVoiceChatManagement: VoiceChatManagement {
    func requestPermission() async throws {
        print("call \(#function)")
    }
    
    func startRecording() throws -> AsyncThrowingStream<VoiceChatResponse, any Error> {
        print("call \(#function)")
        return .makeStream().stream
    }
    
    func stopRecording() {
        print("call \(#function)")
    }
    
    func speak(_ message: String) {
        print("call \(#function), message: \(message)")
    }
    
    func prewarm() throws {
        print("call \(#function)")
    }
}
