//
//  CameraViewModel.swift
//  BarcodeScanner
//
//  Created by Aditya Medhane on 01/07/24.
//

import Foundation
import SwiftUI
import Combine
import AVFoundation

class CameraViewModel: ObservableObject {
    @Published var isCameraViewPresented = false
    @Published var takenPhoto: UIImage?
    
    func takePhoto() {
        isCameraViewPresented = true
    }
    
    func savePhoto() {
        guard let image = takenPhoto else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
}

