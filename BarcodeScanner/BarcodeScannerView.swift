import SwiftUI
import AVFoundation

class BarcodeScannerViewModel: ObservableObject {
    @Published var scannedCode: String = "Not Scanned Yet"
    @Published var isScanning = false
    @Published var capturedImage: UIImage?
    @Published var showingImagePicker = false
}

struct BarcodeScannerView: View {
    @StateObject private var viewModel = BarcodeScannerViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let capturedImage = viewModel.capturedImage {
                    Image(uiImage: capturedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 300)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray, lineWidth: 2)
                        )
                } else if viewModel.isScanning {
                    ScannerView(scannedCode: $viewModel.scannedCode, isScanning: $viewModel.isScanning)
                        .frame(maxWidth: .infinity, maxHeight: 300)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray, lineWidth: 2)
                        )
                } else {
                    Rectangle()
                        .frame(maxWidth: .infinity, maxHeight: 300)
                        .foregroundColor(.gray.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            Text("Camera View")
                                .font(.headline)
                                .foregroundColor(.gray)
                        )
                }
                
                Spacer().frame(height: 40)
                
                VStack(spacing: 10) {
                    Label("Scanned Barcode", systemImage: "barcode.viewfinder")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text(viewModel.scannedCode)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(viewModel.scannedCode == "Not Scanned Yet" ? .red : .green)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(radius: 5)
                        )
                }
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button(action: {
                        viewModel.isScanning.toggle()
                    }) {
                        Text(viewModel.isScanning ? "Stop Scanning" : "Start Scanning")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(viewModel.isScanning ? Color.red : Color.green)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        viewModel.showingImagePicker = true
                    }) {
                        Text("Take Photo")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .padding()
            .navigationTitle("Barcode Scanner")
            .sheet(isPresented: $viewModel.showingImagePicker) {
                ImagePicker(sourceType: .camera) { image in
                    viewModel.capturedImage = image
                    if let barcode = scanBarcode(from: image) {
                        viewModel.scannedCode = barcode
                    } else {
                        viewModel.scannedCode = "No Barcode Found"
                    }
                }
            }
        }
    }
    
    private func scanBarcode(from image: UIImage) -> String? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        let features = detector?.features(in: ciImage) ?? []
        
        for feature in features {
            if let barcodeFeature = feature as? CIQRCodeFeature {
                return barcodeFeature.messageString
            }
        }
        
        return nil
    }
}

struct ScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String
    @Binding var isScanning: Bool
    
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: ScannerView
        var captureSession: AVCaptureSession?
        
        init(parent: ScannerView) {
            self.parent = parent
        }
        
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let stringValue = readableObject.stringValue else { return }
                
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                parent.scannedCode = stringValue
                parent.isScanning = false
                captureSession?.stopRunning()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        
        let captureSession = AVCaptureSession()
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return viewController }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return viewController
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return viewController
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr, .ean13, .ean8, .code128] // Add the types of barcodes you want to scan
        } else {
            return viewController
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = viewController.view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        viewController.view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
        context.coordinator.captureSession = captureSession
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if isScanning {
            context.coordinator.captureSession?.startRunning()
        } else {
            context.coordinator.captureSession?.stopRunning()
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    var completion: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.completion(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
    BarcodeScannerView()
}
