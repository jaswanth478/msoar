import ScreenCaptureKit
import AVFoundation
import Foundation
import CoreFoundation

class AudioRecorder: NSObject, SCStreamOutput {
    private let stream: SCStream
    private var audioFile: AVAudioFile?
    private let outputURL: URL

    init(content: SCShareableContent, outputURL: URL) throws {
        self.outputURL = outputURL

        guard let display = content.displays.first else {
            throw NSError(domain: "AudioRecorder", code: -1, userInfo: [NSLocalizedDescriptionKey: "No display found"])
        }

        let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
        let configuration = SCStreamConfiguration()
        configuration.capturesAudio = true
        configuration.excludesCurrentProcessAudio = true
        configuration.width = 2
        configuration.height = 2
        configuration.showsCursor = false
        configuration.minimumFrameInterval = CMTimeMake(value: 1, timescale: 30)


        self.stream = SCStream(filter: filter, configuration: configuration, delegate: nil)
        super.init()
        try stream.addStreamOutput(self, type: .audio, sampleHandlerQueue: .global())
    }

    func startRecording() {
    stream.startCapture()
}

func stopRecording() {
    stream.stopCapture()
    audioFile = nil
}


    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {

        guard type == .audio,
              CMSampleBufferDataIsReady(sampleBuffer),
              let formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer),
              let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
            return
        }

        if audioFile == nil {
            let format = AVAudioFormat(cmAudioFormatDescription: formatDesc)
            do {
                audioFile = try AVAudioFile(forWriting: outputURL, settings: format.settings)
            } catch {
                return
            }
        }

        guard let format = audioFile?.processingFormat else { return }

        let numSamples = CMSampleBufferGetNumSamples(sampleBuffer)
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(numSamples)) else {
            return
        }

        pcmBuffer.frameLength = pcmBuffer.frameCapacity
        let audioBuffer = pcmBuffer.audioBufferList.pointee.mBuffers

        let status = CMBlockBufferCopyDataBytes(
            blockBuffer,
            atOffset: 0,
            dataLength: Int(audioBuffer.mDataByteSize),
            destination: audioBuffer.mData!
        )

        if status != noErr {
            return
        }

        do {
            try audioFile?.write(from: pcmBuffer)
        } catch {
            print(error)
        }
    }
}

func main() {
    let outputURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent("output.wav")

    print("📍 Will write to: \(outputURL.path)")

    let signalSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
    signal(SIGINT, SIG_IGN)
    signalSource.setEventHandler {
        print("\n Stopping recording")
        AudioRecorderApp.recorder?.stopRecording()
        CFRunLoopStop(CFRunLoopGetMain())
    }
    signalSource.resume()

    SCShareableContent.getExcludingDesktopWindows(false, onScreenWindowsOnly: false) { content, error in
        if let error = error {
            print(error)
            CFRunLoopStop(CFRunLoopGetMain())
            return
        }
        guard let content = content else {
            CFRunLoopStop(CFRunLoopGetMain())
            return
        }

        do {
            let recorder = try AudioRecorder(content: content, outputURL: outputURL)
            AudioRecorderApp.recorder = recorder
            recorder.startRecording()
            print("🎙️ Recording started... Press Ctrl+C to stop.")
        } catch {
            CFRunLoopStop(CFRunLoopGetMain())
        }
    }

    CFRunLoopRun()
}

enum AudioRecorderApp {
    static var recorder: AudioRecorder?
}

main()
import ScreenCaptureKit
import AVFoundation
import Foundation
import CoreFoundation

class AudioRecorder: NSObject, SCStreamOutput {
    private let stream: SCStream
    private var audioFile: AVAudioFile?
    private let outputURL: URL

    init(content: SCShareableContent, outputURL: URL) throws {
        self.outputURL = outputURL

        guard let display = content.displays.first else {
            throw NSError(domain: "AudioRecorder", code: -1, userInfo: [NSLocalizedDescriptionKey: "No display found"])
        }

        let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
        let configuration = SCStreamConfiguration()
        configuration.capturesAudio = true
        configuration.excludesCurrentProcessAudio = true
        configuration.width = 2
        configuration.height = 2
        configuration.showsCursor = false
        configuration.minimumFrameInterval = CMTimeMake(value: 1, timescale: 30)


        self.stream = SCStream(filter: filter, configuration: configuration, delegate: nil)
        super.init()
        try stream.addStreamOutput(self, type: .audio, sampleHandlerQueue: .global())
    }

    func startRecording() {
    stream.startCapture()
}

func stopRecording() {
    stream.stopCapture()
    audioFile = nil
}


    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {

        guard type == .audio,
              CMSampleBufferDataIsReady(sampleBuffer),
              let formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer),
              let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
            return
        }

        if audioFile == nil {
            let format = AVAudioFormat(cmAudioFormatDescription: formatDesc)
            do {
                audioFile = try AVAudioFile(forWriting: outputURL, settings: format.settings)
            } catch {
                return
            }
        }

        guard let format = audioFile?.processingFormat else { return }

        let numSamples = CMSampleBufferGetNumSamples(sampleBuffer)
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(numSamples)) else {
            return
        }

        pcmBuffer.frameLength = pcmBuffer.frameCapacity
        let audioBuffer = pcmBuffer.audioBufferList.pointee.mBuffers

        let status = CMBlockBufferCopyDataBytes(
            blockBuffer,
            atOffset: 0,
            dataLength: Int(audioBuffer.mDataByteSize),
            destination: audioBuffer.mData!
        )

        if status != noErr {
            return
        }

        do {
            try audioFile?.write(from: pcmBuffer)
        } catch {
            print(error)
        }
    }
}

func main() {
    let outputURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent("output.wav")

    print("📍 Will write to: \(outputURL.path)")

    let signalSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
    signal(SIGINT, SIG_IGN)
    signalSource.setEventHandler {
        print("\n Stopping recording")
        AudioRecorderApp.recorder?.stopRecording()
        CFRunLoopStop(CFRunLoopGetMain())
    }
    signalSource.resume()

    SCShareableContent.getExcludingDesktopWindows(false, onScreenWindowsOnly: false) { content, error in
        if let error = error {
            print(error)
            CFRunLoopStop(CFRunLoopGetMain())
            return
        }
        guard let content = content else {
            CFRunLoopStop(CFRunLoopGetMain())
            return
        }

        do {
            let recorder = try AudioRecorder(content: content, outputURL: outputURL)
            AudioRecorderApp.recorder = recorder
            recorder.startRecording()
            print("🎙️ Recording started... Press Ctrl+C to stop.")
        } catch {
            CFRunLoopStop(CFRunLoopGetMain())
        }
    }

    CFRunLoopRun()
}

enum AudioRecorderApp {
    static var recorder: AudioRecorder?
}

main()
