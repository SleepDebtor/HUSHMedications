import Foundation
import UIKit
import CoreGraphics

public struct LabelPDFRenderer {
    public static let pointsPerInch: CGFloat = 72

    /// Render a 1x2 inch PDF label.
    /// - Parameter label: MedicationLabel providing content.
    /// - Parameter dpi: Rendering DPI (default 144 for sharper print). 1 inch = dpi points on each axis.
    /// - Returns: PDF data for the label.
    public static func renderLabel(for label: MedicationLabel, dpi: CGFloat = 144) -> Data? {
        let pageWidth: CGFloat = 2 * dpi
        let pageHeight: CGFloat = 1 * dpi
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let format = UIGraphicsPDFRendererFormat()
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            let cgContext = ctx.cgContext
            cgContext.interpolationQuality = .none
            cgContext.setAllowsAntialiasing(true)
            cgContext.setShouldAntialias(true)

            // Layout constants
            let padding: CGFloat = pageHeight * 0.06 // small margin
            let contentRect = pageRect.insetBy(dx: padding, dy: padding)

            // Left: QR square
            let qrSide = contentRect.height
            let qrRect = CGRect(x: contentRect.minX, y: contentRect.minY, width: qrSide, height: qrSide)

            // Right: text column
            let spacing: CGFloat = 2
            let textLeft = qrRect.maxX + padding * 0.6
            let textWidth = max(0, contentRect.maxX - textLeft)

            // Draw QR image
            var qrImage: UIImage?
            if let data = label.qrImageData, let img = UIImage(data: data) {
                qrImage = img
            } else if let url = label.qrURL, let data = QRCodeGenerator.generate(from: url, scale: max(4, dpi/24)) {
                qrImage = UIImage(data: data)
            }
            if let qr = qrImage {
                // Fit QR into square maintaining aspect
                let fitted = AVMakeRect(aspectRatio: qr.size, insideRect: qrRect)
                qr.draw(in: fitted)
            }

            // Prepare text attributes
            let patientFont = UIFont.boldSystemFont(ofSize: min(14, pageHeight * 0.22))
            let medFont = UIFont.boldSystemFont(ofSize: min(12, pageHeight * 0.18))
            let sigFont = UIFont.systemFont(ofSize: min(10, pageHeight * 0.16))
            let pharmacyFont = UIFont.italicSystemFont(ofSize: min(9, pageHeight * 0.14))

            let paragraph = NSMutableParagraphStyle()
            paragraph.lineBreakMode = .byWordWrapping

            // Build text frames
            var cursorY = contentRect.minY
            let textX = textLeft
            let maxTextWidth = textWidth

            func draw(_ string: String, font: UIFont) {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .paragraphStyle: paragraph
                ]
                let attributed = NSAttributedString(string: string, attributes: attrs)
                let size = attributed.boundingRect(with: CGSize(width: maxTextWidth, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).size
                let rect = CGRect(x: textX, y: cursorY, width: maxTextWidth, height: ceil(size.height))
                attributed.draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
                cursorY = rect.maxY + spacing
            }

            // Content strings (fall back to empty if not set)
            draw(labelValue(label.medicationName, fallback: ""), font: patientFont) // patient name not present in model; using medicationName placeholder if needed
            draw(labelValue(label.medicationName, fallback: ""), font: medFont)
            draw(labelValue(label.sig, fallback: ""), font: sigFont)
            draw(labelValue(label.pharmacyIdentifier, fallback: ""), font: pharmacyFont)
        }

        return data
    }

    private static func labelValue(_ s: String?, fallback: String) -> String {
        if let s = s, !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return s }
        return fallback
    }
}

// MARK: - MedicationLabel convenience
extension MedicationLabel {
    /// Generate a 1x2 inch PDF label for this record.
    /// - Parameter dpi: DPI used for layout and rendering (default 144 for crisp printing)
    /// - Returns: PDF data if rendering succeeds.
    func generatePDFLabel(dpi: CGFloat = 144) -> Data? {
        LabelPDFRenderer.renderLabel(for: self, dpi: dpi)
    }
}
