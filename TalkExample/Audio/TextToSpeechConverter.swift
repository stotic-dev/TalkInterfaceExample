//
//  TextToSpeechConverter.swift
//  TalkExample
//
//  Created by 佐藤汰一 on 2025/11/01.
//

import AVFoundation

public class TextToSpeechConverter {
    let speechSynthesizer:AVSpeechSynthesizer

    public init() {
        speechSynthesizer = AVSpeechSynthesizer()
    }

    // 通常の話し方
    func speakNormal(text: String, language: String = "ja-JP") {
        let speechUtterance = AVSpeechUtterance(string: text)
        speechUtterance.voice = AVSpeechSynthesisVoice(language: language)
        speechUtterance.rate = AVSpeechUtteranceDefaultSpeechRate
        speechUtterance.pitchMultiplier = 1.0
        speechUtterance.volume = 1.0
        speechSynthesizer.speak(speechUtterance)
    }
}
