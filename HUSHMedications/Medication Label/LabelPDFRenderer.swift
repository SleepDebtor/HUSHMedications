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

        // Left: QR square - approx half width minus margin for "Beaker Pharmacy" above QR
        // We'll allocate the left half for QR and "Beaker Pharmacy" text above
        let leftColumnWidth = contentRect.width * 0.48
        let qrSide = leftColumnWidth
        let qrRect = CGRect(x: contentRect.minX, y: contentRect.minY + pageHeight*0.14, width: qrSide, height: qrSide)

        // Right column rectangle and origin for text
        let spacing: CGFloat = 4 // slightly tighter spacing for multiple lines
        let rightColumnX = qrRect.maxX + padding * 0.6
        let rightColumnWidth = contentRect.maxX - rightColumnX

        // Fonts (sizes relative to pageHeight, capped reasonably)
        let beakerFont = CTFontCreateWithName("Helvetica" as CFString, min(8, pageHeight * 0.10), nil)
        let patientFont = CTFontCreateWithName("Helvetica-Bold" as CFString, min(18, pageHeight * 0.26), nil)
        let medFont = CTFontCreateWithName("Helvetica" as CFString, min(14, pageHeight * 0.20), nil)
        let italicFont = CTFontCreateWithName("Helvetica-Oblique" as CFString, min(11, pageHeight * 0.16), nil)
        let monoFont = CTFontCreateWithName("Menlo-Regular" as CFString, min(14, pageHeight * 0.20), nil)
        let boldMonoFont = CTFontCreateWithName("Menlo-Bold" as CFString, min(14, pageHeight * 0.20), nil)
        let prescriberNameFont = CTFontCreateWithName("Helvetica-Bold" as CFString, min(13, pageHeight * 0.18), nil)
        let prescriberPhoneFont = CTFontCreateWithName("Helvetica" as CFString, min(13, pageHeight * 0.18), nil)
        let clinicFont = CTFontCreateWithName("Helvetica" as CFString, min(12, pageHeight * 0.16), nil)
        let pharmacyFillFont = CTFontCreateWithName("Helvetica-Bold" as CFString, min(12, pageHeight * 0.16), nil)

        // Draw "Beaker Pharmacy" above QR code, centered horizontally over QR
        let beakerString = "Beaker Pharmacy"
        let beakerAttr = [NSAttributedString.Key.font: beakerFont] as CFDictionary
        let beakerAttrString = CFAttributedStringCreate(nil, beakerString as CFString, beakerAttr)!
        let beakerFramesetter = CTFramesetterCreateWithAttributedString(beakerAttrString)
        let beakerHeight = suggestedHeight(framesetter: beakerFramesetter, width: qrSide)
        let beakerRect = CGRect(x: qrRect.minX, y: contentRect.minY, width: qrSide, height: beakerHeight)
        drawCT(framesetter: beakerFramesetter, in: beakerRect, context: ctx)

        // Draw QR image
        if let cgImage = loadQRImage(for: label, dpi: dpi) {
            let fitted = aspectFitRect(imageSize: CGSize(width: cgImage.width, height: cgImage.height), in: qrRect)
            ctx.draw(cgImage, in: fitted)
        }

        // Start drawing text lines in right column, top-aligned
        var cursorY = contentRect.minY

        func drawText(_ string: String, font: CTFont) {
            let attr = [NSAttributedString.Key.font: font] as CFDictionary
            let attributed = CFAttributedStringCreate(nil, string as CFString, attr)!
            let framesetter = CTFramesetterCreateWithAttributedString(attributed)
            let height = suggestedHeight(framesetter: framesetter, width: rightColumnWidth)
            let rect = CGRect(x: rightColumnX, y: cursorY, width: rightColumnWidth, height: height)
            drawCT(framesetter: framesetter, in: rect, context: ctx)
            cursorY = rect.maxY + spacing
        }

        func drawItalic(_ string: String) {
            drawText(string, font: italicFont)
        }

        func drawMono(_ string: String) {
            drawText(string, font: monoFont)
        }

        func drawBoldMono(_ string: String) {
            drawText(string, font: boldMonoFont)
        }

        func drawBold(_ string: String) {
            drawText(string, font: prescriberNameFont)
        }

        func drawRegular(_ string: String) {
            drawText(string, font: medFont)
        }

        // 1. Patient name (bold, large, usually 18pt)
        let patientName = label.patient?.fullName ?? "Last, First"
        // Draw patient name (bold large)
        // Line 1
        drawText(patientName, font: patientFont)

        // 2. Medication name and dose (regular, large)
        // Construct med name + dose line
        var medLine: String {
            var line = ""
            if let medName = label.medication?.medicationName {
                line = medName
            } else if label.medicationName.isNotEmpty {
                line = label.medicationName
            } else {
                line = "Some Medication"
            }
            if label.dose.isNotEmpty {
                line += " \(label.dose)"
            }
            return line
        }
        // Line 2
        drawRegular(medLine)

        // 3. Secondary ingredient (italics, smaller, optional)
        // Check if medication has concentrationSecondaryMedicationPerMl string
        if let concSecondary = label.medication?.concentrationSecondaryMedicationPerMl?.singleDecimalStr, !concSecondary.isEmpty {
            // Line 3 (italics)
            drawItalic(concSecondary)
        }

        // 4. Disp amount line (monospaced, large)
        // Use dispAmountLine from label.dispensedAmountLine (assumed property string)
        let dispAmount = label.dispenseAmount.singleDecimalStr
        drawMono(dispAmount)
        

        // 5. SIG (monospaced, large)
        // Line 5
        drawMono(label.sig)

        // 6. Prescriber (bold for name/MD, phone number right-aligned)
        // We'll draw prescriber name (bold) left-aligned
        // and phone number right-aligned on same line

        // Extract prescriber name and phone number from label
        // TODO: Add provider
        let prescriberName = "Krista Lazar"
        let prescriberPhone = "717 497-4778"

        // We draw prescriber line manually to handle left/right alignment

        if !prescriberName.isEmpty || !prescriberPhone.isEmpty {
            // Measure prescriber name height using prescriberNameFont
            let prescriberNameAttr = [NSAttributedString.Key.font: prescriberNameFont] as CFDictionary
            let prescriberNameAttrString = CFAttributedStringCreate(nil, prescriberName as CFString, prescriberNameAttr)!
            let prescriberNameFramesetter = CTFramesetterCreateWithAttributedString(prescriberNameAttrString)
            let prescriberHeight = suggestedHeight(framesetter: prescriberNameFramesetter, width: rightColumnWidth / 2)

            // Draw prescriber name left side
            let prescriberNameRect = CGRect(x: rightColumnX, y: cursorY, width: rightColumnWidth / 2, height: prescriberHeight)
            drawCT(framesetter: prescriberNameFramesetter, in: prescriberNameRect, context: ctx)

            // Draw prescriber phone right side, if present
            if !prescriberPhone.isEmpty {
                let prescriberPhoneAttr = [NSAttributedString.Key.font: prescriberPhoneFont] as CFDictionary
                let prescriberPhoneAttrString = CFAttributedStringCreate(nil, prescriberPhone as CFString, prescriberPhoneAttr)!
                let prescriberPhoneFramesetter = CTFramesetterCreateWithAttributedString(prescriberPhoneAttrString)
                let phoneSize = CTFramesetterSuggestFrameSizeWithConstraints(prescriberPhoneFramesetter, CFRange(location: 0, length: 0), nil, CGSize(width: rightColumnWidth / 2, height: CGFloat.greatestFiniteMagnitude), nil)
                let phoneHeight = ceil(phoneSize.height)
                let phoneWidth = ceil(phoneSize.width)

                let phoneX = rightColumnX + rightColumnWidth - phoneWidth
                let prescriberPhoneRect = CGRect(x: phoneX, y: cursorY, width: phoneWidth, height: phoneHeight)
                drawCT(framesetter: prescriberPhoneFramesetter, in: prescriberPhoneRect, context: ctx)

                cursorY = max(prescriberNameRect.maxY, prescriberPhoneRect.maxY) + spacing
            } else {
                cursorY = prescriberNameRect.maxY + spacing
            }
        }

        // 7. Clinic address (regular)
        let clinicAddress = "400 Market Street, Williamsport, PA 17701"
        drawText(clinicAddress, font: clinicFont)
    

        // 8. Pharmacy fill instruction (bold)
        // Format fillAmount if present
        let fillAmount = label.fillAmount.singleDecimalStr
            // Example: "Refills: X" or other text as per format in label.fillAmount
            drawText(fillAmount, font: pharmacyFillFont)

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
