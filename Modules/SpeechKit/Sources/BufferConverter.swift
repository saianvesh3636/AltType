import Foundation
import AVFoundation

/// Converts microphone tap buffers to the SpeechAnalyzer-compatible format.
/// SpeechAnalyzer performs no audio conversion itself, so buffers must arrive
/// pre-converted to `SpeechAnalyzer.bestAvailableAudioFormat`.
///
/// Accessed only from the audio tap thread — one instance per recording session.
final class BufferConverter: @unchecked Sendable {

    enum ConversionError: Error {
        case failedToCreateConverter
        case failedToAllocateBuffer
        case conversionFailed(String)
    }

    private var converter: AVAudioConverter?

    func convert(_ buffer: AVAudioPCMBuffer, to format: AVAudioFormat) throws -> AVAudioPCMBuffer {
        let inputFormat = buffer.format
        guard inputFormat != format else { return buffer }

        if converter == nil || converter?.outputFormat != format {
            converter = AVAudioConverter(from: inputFormat, to: format)
            // Avoid any timestamp drift from priming frames — keeps CMTime sample-accurate
            converter?.primeMethod = .none
        }

        guard let converter = converter else {
            throw ConversionError.failedToCreateConverter
        }

        let sampleRateRatio = converter.outputFormat.sampleRate / converter.inputFormat.sampleRate
        let scaledFrameLength = (Double(buffer.frameLength) * sampleRateRatio).rounded(.up)
        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: converter.outputFormat,
            frameCapacity: AVAudioFrameCount(max(scaledFrameLength, 1))
        ) else {
            throw ConversionError.failedToAllocateBuffer
        }

        var nsError: NSError?
        var bufferProvided = false
        let status = converter.convert(to: outputBuffer, error: &nsError) { _, inputStatusPointer in
            if bufferProvided {
                inputStatusPointer.pointee = .noDataNow
                return nil
            }
            bufferProvided = true
            inputStatusPointer.pointee = .haveData
            return buffer
        }

        guard status != .error else {
            throw ConversionError.conversionFailed(nsError?.localizedDescription ?? "unknown AVAudioConverter error")
        }

        return outputBuffer
    }
}
