import Foundation
import CoreGraphics
import CoreImage
import CoreText
import ImageIO

public struct LabelPDFRenderer {
    public static let pointsPerInch: CGFloat = 72

    /// Render a 1x2 inch PDF label (cross-platform Core Graphics implementation).
    /// - Parameter label: MedicationLabel providing content.
    /// - Parameter dpi: Rendering DPI (default 144 for sharper print). 1 inch = dpi points on each axis.
    /// - Returns: PDF data for the label.
   static func renderLabel(for label: MedicationLabel, dpi: CGFloat = 144) -> Data? {
        let pageWidth: CGFloat = 2 * dpi
        let pageHeight: CGFloat = 1 * dpi
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let mutableData = NSMutableData()
        guard let consumer = CGDataConsumer(data: mutableData as CFMutableData) else { return nil }
        var mediaBox = pageRect
        guard let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return nil }

        ctx.beginPDFPage(nil)
        ctx.interpolationQuality = .none
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)

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
        if let cgImage = loadQRImage(for: label, dpi: dpi) {
            let fitted = aspectFitRect(imageSize: CGSize(width: cgImage.width, height: cgImage.height), in: qrRect)
            ctx.draw(cgImage, in: fitted)
        }

        // Text fonts
        let patientFont = CTFontCreateWithName("Helvetica-Bold" as CFString, min(14, pageHeight * 0.22), nil)
        let medFont = CTFontCreateWithName("Helvetica-Bold" as CFString, min(12, pageHeight * 0.18), nil)
        let sigFont = CTFontCreateWithName("Helvetica" as CFString, min(10, pageHeight * 0.16), nil)
        let pharmacyFont = CTFontCreateWithName("Helvetica-Oblique" as CFString, min(9, pageHeight * 0.14), nil)

        // Build and draw text frames
        var cursorY = contentRect.minY
        let textX = textLeft
        let maxTextWidth = textWidth

        func drawText(_ string: String, font: CTFont) {
            let attr = [NSAttributedString.Key.font: font] as CFDictionary
            let attributed = CFAttributedStringCreate(nil, string as CFString, attr)!
            let framesetter = CTFramesetterCreateWithAttributedString(attributed)
            let height = suggestedHeight(framesetter: framesetter, width: maxTextWidth)
            let rect = CGRect(x: textX, y: cursorY, width: maxTextWidth, height: ceil(height))
            drawCT(framesetter: framesetter, in: rect, context: ctx)
            cursorY = rect.maxY + spacing
        }

        let patientName = label.patient?.fullName ?? ""
        drawText(patientName, font: patientFont)
        drawText(label.medicationName, font: medFont)
        drawText(label.sig, font: sigFont)
        drawText(label.pharmacyIdentifier, font: pharmacyFont)

        ctx.endPDFPage()
        ctx.closePDF()
        return mutableData as Data
    }

    // MARK: - Helpers
    private static func loadQRImage(for label: MedicationLabel, dpi: CGFloat) -> CGImage? {
        if let data = label.qrImageData, let img = cgImageFromPNGData(data) {
            return img
        }
        if let url = label.qrURL, let data = QRCodeGenerator.generate(from: url, scale: max(4, dpi/24)) {
            return cgImageFromPNGData(data)
        }
        return nil
    }

    private static func cgImageFromPNGData(_ data: Data) -> CGImage? {
        let cfData = data as CFData
        guard let src = CGImageSourceCreateWithData(cfData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(src, 0, nil)
    }

    private static func aspectFitRect(imageSize: CGSize, in bounding: CGRect) -> CGRect {
        guard imageSize.width > 0 && imageSize.height > 0 else { return bounding }
        let scale = min(bounding.width / imageSize.width, bounding.height / imageSize.height)
        let w = imageSize.width * scale
        let h = imageSize.height * scale
        let x = bounding.midX - w / 2
        let y = bounding.midY - h / 2
        return CGRect(x: x, y: y, width: w, height: h)
    }

    private static func suggestedHeight(framesetter: CTFramesetter, width: CGFloat) -> CGFloat {
        let constraint = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let size = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRange(location: 0, length: 0), nil, constraint, nil)
        return ceil(size.height)
    }

    private static func drawCT(framesetter: CTFramesetter, in rect: CGRect, context: CGContext) {
        // Core Text uses a flipped coordinate system; adjust
        context.saveGState()
        context.textMatrix = .identity
        context.translateBy(x: rect.minX, y: rect.maxY)
        context.scaleBy(x: 1.0, y: -1.0)

        let path = CGMutablePath()
        path.addRect(CGRect(x: 0, y: 0, width: rect.width, height: rect.height))
        let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: 0, length: 0), path, nil)
        CTFrameDraw(frame, context)
        context.restoreGState()
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
