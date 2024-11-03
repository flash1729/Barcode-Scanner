//
//  MockCameraView.swift
//  BarcodeScanner
//
//  Created by Aditya Medhane on 01/07/24.
//

import SwiftUI

struct MockCameraView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var image: UIImage?

    var body: some View {
        VStack {
            Text("Mock Camera View")
                .font(.largeTitle)
                .padding()
            
            Button("Simulate Taking Photo") {
                print("Simulating taking photo")
                image = UIImage(systemName: "photo") // Using a system image as a mock photo
                print("Image set: \(image != nil)")
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
        }
    }
}

//#Preview {
//    MockCameraView()
//}
