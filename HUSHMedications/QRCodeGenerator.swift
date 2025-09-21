import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

/// Utility for generating QR codes as PNG data
public struct QRCodeGenerator {
    /// Generate a QR code PNG from a string.
    /// - Parameters:
    ///   - string: The content to encode in the QR code.
    ///   - scale: Integer-like scale factor applied to the CIImage to increase resolution (default 6).
    /// - Returns: PNG data for the generated QR code, or nil if generation fails.
    public static func generate(from string: String, scale: CGFloat = 6) -> Data? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        // Medium error correction level for balance between density and resilience
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }

        // Scale up the QR to make it crisp when rendered/printed
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let scaledImage = outputImage.transformed(by: transform)

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }

        let uiImage = UIImage(cgImage: cgImage)
        return uiImage.pngData()
    }

    /// Generate a QR code PNG from a URL.
    /// - Parameters:
    ///   - url: The URL to encode.
    ///   - scale: Integer-like scale factor applied to the CIImage to increase resolution (default 6).
    /// - Returns: PNG data for the generated QR code, or nil if generation fails.
    public static func generate(from url: URL, scale: CGFloat = 6) -> Data? {
        generate(from: url.absoluteString, scale: scale)
    }
}

// MARK: - MedicationLabel convenience
extension MedicationLabel {
    /// Regenerate and store the QR image data from the model's `qrURL`.
    /// - Parameter scale: Scale factor for output resolution (default 6).
    func regenerateQR(scale: CGFloat = 6) {
        if let url = qrURL, let data = QRCodeGenerator.generate(from: url, scale: scale) {
            self.qrImageData = data
        }
    }
}
