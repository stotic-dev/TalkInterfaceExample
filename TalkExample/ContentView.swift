//
//  ContentView.swift
//  TalkExample
//
//  Created by 佐藤汰一 on 2025/10/31.
//

import SwiftUI
import Speech

struct ContentView: View {
    @Environment(\.voiceChatManager) var voiceChatManager
    @State var isRecording = false
    @State var isPresentedAlert = false
    @State var currentError: (any Error)? = nil
    @State var chatMessages: [String] = []
    @State var speakText: String = ""
    @State var textToSpeechConverter = TextToSpeechConverter()
    @State var currentInputIndex = 0
    
    var body: some View {
        VStack {
            // Text-to-Speech input and action
            VStack(alignment: .leading, spacing: 8) {
                Text("読み上げテキスト")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(alignment: .center, spacing: 8) {
                    TextField("ここに読み上げさせたいテキストを入力", text: $speakText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)
                    Button("読み上げ") {
                        tappedSpeakButton()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .foregroundStyle(.white)
                    .background {
                        RoundedRectangle(cornerRadius: 8).fill(speakText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .green)
                    }
                    .disabled(speakText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Button("読み上げ2") {
                        textToSpeechConverter.speakNormal(text: speakText)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .foregroundStyle(.white)
                    .background {
                        RoundedRectangle(cornerRadius: 8).fill(speakText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .green)
                    }
                    .disabled(speakText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(.bottom)
            ZStack {
                Text("Ready speaking!")
                    .foregroundStyle(.gray.opacity(0.8))
                    .opacity(chatMessages.isEmpty ? 1 : 0)
                    .font(.body)
                    .padding()
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke()
                            .fill(.gray)
                    }
                List {
                    ForEach(chatMessages, id: \.self) {
                        Text($0)
                            .font(.body)
                            .padding()
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke()
                                    .fill(.gray)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.horizontal, 16)
                    }
                    .listRowInsets(.none)
                    .listRowSeparator(.hidden)
                }
                .opacity(chatMessages.isEmpty ? 0 : 1)
            }
            
            HStack {
                if isRecording {
                    Button("Stop") {
                        tappedStopButton()
                    }
                    .padding()
                    .foregroundStyle(.white)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.red)
                    }
                }
                else {
                    Button("Start") {
                        tappedStartButton()
                    }
                    .padding()
                    .foregroundStyle(.white)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.blue)
                    }
                }
                Button("Clear") {
                    withAnimation {
                        chatMessages.removeAll()
                    }
                }
                .padding()
                .foregroundStyle(.white)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.red)
                }
            }
            .font(.title)
        }
        .padding()
        .task {
            do {
                try await voiceChatManager.requestPermission()
                try voiceChatManager.prewarm()
            }
            catch {
                currentError = error
                isPresentedAlert = true
            }
        }
        .alert(
            "error: \(currentError?.localizedDescription ?? "nothing")",
            isPresented: $isPresentedAlert
        ) {
            Button("OK") {
                currentError = nil
                withAnimation {
                    isRecording = false
                }
            }
        }
    }
    
    func speakFast(text: String, language: String = "ja-JP") {
        let speechSynthesizer = AVSpeechSynthesizer()
        let speechUtterance = AVSpeechUtterance(string: text)
        speechUtterance.voice = AVSpeechSynthesisVoice(language: language)
        speechUtterance.rate = AVSpeechUtteranceMaximumSpeechRate
        speechUtterance.pitchMultiplier = 1.0
        speechUtterance.volume = 1.0
        speechSynthesizer.speak(speechUtterance)
    }
}

private extension ContentView {
    func tappedSpeakButton() {
        let text = speakText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        voiceChatManager.speak(text)
    }
    
    func tappedStartButton() {
        withAnimation {
            isRecording = true
        }
        
        do {
            let stream = try voiceChatManager.startRecording()
            Task {
                await observeVoiceChatStream(stream)
            }
        } catch {
            currentError = error
            isPresentedAlert = true
        }
    }
    
    func tappedStopButton() {
        withAnimation {
            isRecording = false
        }
        voiceChatManager.stopRecording()
    }
    
    func observeVoiceChatStream(_ stream: AsyncThrowingStream<VoiceChatResponse, any Error>) async {
        do {
            for try await response in stream {
                switch response {
                case .partial(let text):
                    if chatMessages.indices.contains(currentInputIndex) {
                        chatMessages[currentInputIndex] = text
                    } else {
                        chatMessages.append(text)
                    }
                case .finish:
                    currentInputIndex += 1
                }
            }
        }
        catch {
            currentError = error
            isPresentedAlert = true
        }
    }
}

#Preview {
    ContentView()
}

