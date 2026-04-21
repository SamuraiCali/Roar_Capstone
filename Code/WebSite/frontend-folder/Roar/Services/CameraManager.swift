import Foundation
import AVFoundation
internal import Combine

class CameraManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var session = AVCaptureSession()
    @Published var outputURL: URL?
    
    private var videoOutput = AVCaptureMovieFileOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override init() {
        super.init()
        checkPermissions()
    }
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async { self.setupSession() }
                }
            }
        default:
            break
        }
    }
    
    func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .high
        
        // Video Input
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            return
        }
        
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }
        
        // Audio Input
        guard let audioDevice = AVCaptureDevice.default(for: .audio),
              let audioInput = try? AVCaptureDeviceInput(device: audioDevice) else {
            return
        }
        
        if session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }
        
        // Output
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        session.commitConfiguration()
        
        Task {
            session.startRunning()
        }
    }
    
    func startRecording() {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
        videoOutput.startRecording(to: tempURL, recordingDelegate: self)
        isRecording = true
    }
    
    func stopRecording() {
        videoOutput.stopRecording()
        isRecording = false
    }
}

extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording: \(error)")
            return
        }
        DispatchQueue.main.async {
            self.outputURL = outputFileURL
        }
    }
}
