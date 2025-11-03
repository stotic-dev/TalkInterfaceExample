//
//  RecognizerError.swift
//  TalkExample
//
//  Created by 佐藤汰一 on 2025/10/31.
//

enum RecognizerError: Error {
    case nilRecognizer
    case notAuthorizedToRecognize
    case notPermittedToRecord
    case recognizerIsUnavailable
    case alreadyRecording
    
    
    public var message: String {
        switch self {
        case .nilRecognizer: return "Can't initialize speech recognizer"
        case .notAuthorizedToRecognize: return "Not authorized to recognize speech"
        case .notPermittedToRecord: return "Not permitted to record audio"
        case .recognizerIsUnavailable: return "Recognizer is unavailable"
        case .alreadyRecording: return "Already recording"
        }
    }
}
