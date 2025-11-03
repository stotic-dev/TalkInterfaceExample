//
//  AudioProcessor.swift
//  TalkExample
//
//  Created by 佐藤汰一 on 2025/11/01.
//

import AVFoundation

final class AudioProcessor {
    private let session = AVAudioSession.sharedInstance()
    private let engine = AVAudioEngine()
    private let synthesizer: AVSpeechSynthesizer = .init()
    private var speakPlayer = AVAudioPlayerNode()
    private var commonSampleRate: Double = 44100
    
    var callbackBuffer: (MonoAudioBuffer) -> Void = { _ in }
    
    func prewarm() throws {
        setupSession()
        
        setupOutput()
        
        try setupRecording()
        
        engine.prepare()
    }
    
    func startRecording() throws {
        guard !engine.isRunning else {
            print("already recording")
            throw RecognizerError.alreadyRecording
        }
        
        try engine.start()
    }
    
    func stopRecording() {
        engine.attachedNodes.forEach {
            $0.removeTap(onBus: 0)
        }
        callbackBuffer = { _ in }
        engine.stop()
    }
    
    func speakText(_ text: String) {
        guard engine.isRunning else { return }
        
        let utterance = AVSpeechUtterance(string: text)
        // Configure voice to match the current locale if possible
        if let voice = AVSpeechSynthesisVoice(language: "ja_JP") {
            utterance.voice = voice
        }
        // Tune rate/pitch for better intelligibility (within allowed range)
        utterance.rate = Float(commonSampleRate)
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0.0
        utterance.postUtteranceDelay = 0.0
        
        synthesizer.write(utterance) { [weak self] buffer in
            guard let self,
                  let speakBuffer = buffer as? AVAudioPCMBuffer else { return }
            
            self.speakPlayer.scheduleBuffer(speakBuffer, at: nil)
            self.speakPlayer.play()
        }
    }
}

private extension AudioProcessor {
    func setupRecording() throws {
        
        let inputNode = engine.inputNode
        try inputNode.setVoiceProcessingEnabled(true)
        
        let duckingConfig = AVAudioVoiceProcessingOtherAudioDuckingConfiguration(
            enableAdvancedDucking: false,
            duckingLevel: .min
        )
        inputNode.voiceProcessingOtherAudioDuckingConfiguration = duckingConfig
        
        let output = engine.outputNode
        let mixer = engine.mainMixerNode
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        self.commonSampleRate = recordingFormat.sampleRate
        engine.connect(mixer, to: output, format: recordingFormat)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard let self else { return }
            
            self.callbackBuffer(.init(buffer: buffer))
        }
    }
    
    func setupSession() {
        do {
            try session.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [
                    .defaultToSpeaker,
                    .allowBluetoothA2DP,
                    .allowBluetoothHFP,
                ]
            )
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        }
        catch {
            preconditionFailure("Failed setup audio session(error: \(error)).")
        }
    }
    
    func setupOutput() {
        engine.attach(speakPlayer)
                
        let output = engine.outputNode
        let mixer = engine.mainMixerNode
        
        let format = engine.inputNode.outputFormat(forBus: 0)
        engine.connect(speakPlayer, to: mixer, format: format)
        engine.connect(mixer, to: output, format: format)
    }
}
