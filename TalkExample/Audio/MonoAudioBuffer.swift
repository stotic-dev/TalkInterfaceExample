//
//  MonoAudioBuffer.swift
//  TalkExample
//
//  Created by 佐藤汰一 on 2025/11/01.
//

import AVFoundation

struct MonoAudioBuffer {
    let buffer: AVAudioPCMBuffer
    
    func floatData() -> [Float] {
        guard let floatData = buffer.floatChannelData else { return [] }
        let channelData = floatData[0] // モノラルなので最初のチャンネルのみ
        let frameLength = Int(buffer.frameLength)
        
        // UnsafePointer<Float> → [Float] にコピー
        return Array(UnsafeBufferPointer(start: channelData, count: frameLength))
    }
}
