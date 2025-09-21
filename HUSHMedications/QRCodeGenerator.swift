import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import ImageIO
import UniformTypeIdentifiers

/// Utility for generating QR codes as PNG data (cross-platform)
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
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let scaledImage = outputImage.transformed(by: transform)

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }

        // Encode to PNG using ImageIO
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data as CFMutableData, UTType.png.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(dest, cgImage, nil)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return data as Data
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

