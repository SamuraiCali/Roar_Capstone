import SwiftUI
import AVFoundation

struct CameraView: View {
    @StateObject private var manager = CameraManager()
    @State private var timeElapsed: Double = 0
    @State private var timer: Timer?
    @State private var showTagging = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Camera Preview
                GeometryReader { geometry in
                    CameraPreview(session: manager.session, frame: geometry.frame(in: .global))
                        .ignoresSafeArea()
                }
                
                VStack {
                    // Progress Bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.5))
                                .frame(height: 6)
                            
                            Rectangle()
                                .fill(Color.orange) // Roar Gold
                                .frame(width: geometry.size.width * CGFloat(timeElapsed / 30.0), height: 6)
                        }
                    }
                    .frame(height: 6)
                    .padding(.top)
                    
                    Spacer()
                    
                    // Controls
                    HStack {
                        Spacer()
                        
                        // Record Button
                        Button(action: {
                            if manager.isRecording {
                                stopRecording()
                            } else {
                                startRecording()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                                    .frame(width: 70, height: 70)
                                
                                Circle()
                                    .fill(manager.isRecording ? Color.red : Color.white)
                                    .frame(width: 60, height: 60)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
            // Fix: Use navigationDestination(isPresented:)
            .navigationDestination(isPresented: $showTagging) {
                if let url = manager.outputURL {
                    TaggingView(videoURL: url)
                }
            }
            // Fix: Use onChange(of:perform:) with 0 args or new iOS 17 style
            // Here using the iOS 17+ compatible closure (if available) or standard fallback
            .onChange(of: manager.outputURL) { oldValue, newValue in
                if newValue != nil {
                    showTagging = true
                }
            }
        }
    }
    
    func startRecording() {
        manager.startRecording()
        timeElapsed = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            timeElapsed += 0.1
            if timeElapsed >= 30.0 {
                stopRecording()
            }
        }
    }
    
    func stopRecording() {
        manager.stopRecording()
        timer?.invalidate()
        timer = nil
    }
}

struct CameraPreview: UIViewRepresentable {
    var session: AVCaptureSession
    var frame: CGRect
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        // Fix: Use the passed frame instead of UIScreen.main
        previewLayer.frame = frame
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            layer.frame = frame
        }
    }
}
