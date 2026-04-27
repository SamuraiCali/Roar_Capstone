import SwiftUI
import AVFoundation
import PhotosUI

struct CameraView: View {
    @StateObject private var manager = CameraManager()
    @State private var timeElapsed: Double = 0
    @State private var timer: Timer?
    @State private var showTagging = false
    @State private var isProcessingVideo: Bool = false
    
    @State private var selectedItem: PhotosPickerItem?
    
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
                    ZStack {
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
                            
                        }//Hstack
                        .padding(.bottom, 30)
                        
                        HStack {
                            Spacer()
                            
                            PhotosPicker(
                                selection: $selectedItem,
                                matching: .videos,
                                photoLibrary: .shared()
                            ) {
                                Image(systemName: "photo.on.rectangle")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 35, height: 35)
                                    .foregroundColor(.white)
                                    .padding()
                            }
                            .disabled(manager.isRecording)
                            .opacity((manager.isRecording) ? 0.5 : 1)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
                
                if isProcessingVideo {
                    ZStack {
                        Color.black.opacity(0.6)
                            .ignoresSafeArea()
                        
                        ProgressView("Processing video...")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(10)
                    }
                }
            }//zstack
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
            .onChange(of: selectedItem) { _, newItem in
                guard let item = newItem else { return }
                print("Selected Item changed...")
                isProcessingVideo = true
                
                Task {
                    do {
                        if let data = try await item.loadTransferable(type: Data.self) {
                            let tempURL = FileManager.default.temporaryDirectory
                                .appendingPathComponent(UUID().uuidString + ".mov")
                            
                            try data.write(to: tempURL)
                            
                            print("Obtained Video URL: \(tempURL)")
                            
                            await MainActor.run {
                                manager.outputURL = tempURL
                                isProcessingVideo = false
                            }
                        } else {
                            print("❌ Failed to load video data")
                            isProcessingVideo = false
                        }
                    } catch {
                        print("❌ Error loading video: \(error)")
                        isProcessingVideo = false
                    }
                
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
