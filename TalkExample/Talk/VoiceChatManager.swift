//
//  VoiceChatManager.swift
//  TalkExample
//
//  Created by 佐藤汰一 on 2025/10/31.
//

import AVFoundation
import Speech
import SwiftUI

final class VoiceChatManager: VoiceChatManagement {
    private let session = AVAudioSession.sharedInstance()
    private var task: SFSpeechRecognitionTask?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private let recognizer: SFSpeechRecognizer
    private let audioProcessor = AudioProcessor()
    private var recognizeInitialTask: Task<Void, any Error>? = nil
        
    private var continuation: AsyncThrowingStream<VoiceChatResponse, Error>.Continuation?
    
    init() {
        guard let recognizer = SFSpeechRecognizer(locale: .init(identifier: "ja_JP")) else {
            preconditionFailure("Unexpectedly failed to create a recognizer.")
        }
        self.recognizer = recognizer
    }
    
    @MainActor
    func requestPermission() async throws {
        guard await SFSpeechRecognizer.hasAuthorizationToRecognize() else {
            throw RecognizerError.notAuthorizedToRecognize
        }
        guard await AVAudioSession.sharedInstance().hasPermissionToRecord() else {
            throw RecognizerError.notPermittedToRecord
        }
    }
    
    func prewarm() throws {
        try audioProcessor.prewarm()
    }
    
    func startRecording() throws -> AsyncThrowingStream<VoiceChatResponse, Error> {
        
        let (stream, continuation) = AsyncThrowingStream<VoiceChatResponse, Error>.makeStream(bufferingPolicy: .bufferingNewest(1))
        self.continuation = continuation
        
        // SpeechRecognizerにSpeechToTextを行わせる処理
        startSpeechRecognition()
        
        try audioProcessor.startRecording()
        
        return stream
    }
    
    func stopRecording() {
        
        stopRecording(error: nil)
    }
    
    func speak(_ message: String) {
        audioProcessor.speakText(message)
    }
}

private extension VoiceChatManager {
    
    func startSpeechRecognition() {
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.request = request
        
        audioProcessor.callbackBuffer = { [weak self] in
            guard let self else { return }
            self.request?.append($0.buffer)
        }
        
        self.task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            self.recognitionHandler(result: result, error: error)
        }
    }
    
    func recognitionHandler(result: SFSpeechRecognitionResult?, error: Error?) {
        if result?.isFinal ?? false {
            continuation?.yield(.finish)
            return
        }
        
        if let error {
            print("error: \(error)")
            return
        }
        
        recognizeInitialTask?.cancel()
        
        guard let result else { return }
        continuation?.yield(.partial(result.bestTranscription.formattedString))
        
        recognizeInitialTask = Task {
            try await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            request?.endAudio()
            startSpeechRecognition()
            print("Listening next speech...")
        }
    }
    
    func stopRecording(error: Error? = nil) {
        request?.endAudio()
        
        do {
            try session.setActive(false, options: .notifyOthersOnDeactivation)
        }
        catch {
            continuation?.yield(with: .failure(error))
        }
        
        audioProcessor.stopRecording()
        
        if let error {
            continuation?.finish(throwing: error)
        } else {
            continuation?.finish()
        }
    }
}

extension SFSpeechRecognizer {
    static func hasAuthorizationToRecognize() async -> Bool {
        await withCheckedContinuation { continuation in
            requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
}

extension AVAudioSession {
    func hasPermissionToRecord() async -> Bool {
        return await AVAudioApplication.requestRecordPermission()
    }
}
