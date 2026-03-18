import UIKit
import CoreGraphics

// MARK: - Page constants
enum PDFLayout {
    static let pageWidth:  CGFloat = 595
    static let pageHeight: CGFloat = 842
    static let marginH:    CGFloat = 50
    static let marginV:    CGFloat = 50
    static var contentWidth: CGFloat { pageWidth - marginH * 2 }
    static var contentX: CGFloat { marginH }
    static var contentEndX: CGFloat { pageWidth - marginH }
}

// MARK: - Text drawing
func pdfDrawText(
    _ text: String,
    in rect: CGRect,
    font: UIFont,
    color: UIColor = .black,
    alignment: NSTextAlignment = .left,
    lineBreakMode: NSLineBreakMode = .byWordWrapping
) {
    let ps = NSMutableParagraphStyle()
    ps.alignment = alignment
    ps.lineBreakMode = lineBreakMode
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: ps
    ]
    (text as NSString).draw(with: rect, options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
}

// Returns the height used after drawing the text
@discardableResult
func pdfDrawWrappedText(
    _ text: String,
    x: CGFloat, y: CGFloat, width: CGFloat,
    font: UIFont, color: UIColor = .black,
    alignment: NSTextAlignment = .left
) -> CGFloat {
    let ps = NSMutableParagraphStyle()
    ps.alignment = alignment
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: ps]
    let boundingRect = (text as NSString).boundingRect(
        with: CGSize(width: width, height: 10000),
        options: .usesLineFragmentOrigin,
        attributes: attrs,
        context: nil
    )
    pdfDrawText(text, in: CGRect(x: x, y: y, width: width, height: ceil(boundingRect.height)), font: font, color: color, alignment: alignment)
    return ceil(boundingRect.height)
}

// MARK: - Rect + rounded rect
func pdfFillRect(_ rect: CGRect, color: UIColor, cornerRadius: CGFloat = 0) {
    color.setFill()
    if cornerRadius > 0 {
        UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).fill()
    } else {
        UIRectFill(rect)
    }
}

func pdfStrokeRect(_ rect: CGRect, color: UIColor, lineWidth: CGFloat = 1, cornerRadius: CGFloat = 0) {
    color.setStroke()
    let path = cornerRadius > 0
        ? UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        : UIBezierPath(rect: rect)
    path.lineWidth = lineWidth
    path.stroke()
}

// MARK: - Progress bar
func pdfDrawProgressBar(
    progress: Double,
    in rect: CGRect,
    fillColor: UIColor,
    bgColor: UIColor = UIColor.systemGray5
) {
    bgColor.setFill()
    UIBezierPath(roundedRect: rect, cornerRadius: rect.height / 2).fill()
    let fillWidth = CGFloat(min(max(progress / 100, 0), 1)) * rect.width
    if fillWidth > 0 {
        let fillRect = CGRect(x: rect.minX, y: rect.minY, width: fillWidth, height: rect.height)
        fillColor.setFill()
        UIBezierPath(roundedRect: fillRect, cornerRadius: rect.height / 2).fill()
    }
}

// MARK: - Badge / pill
func pdfDrawBadge(text: String, at origin: CGPoint, bgColor: UIColor, textColor: UIColor, font: UIFont) -> CGFloat {
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: textColor]
    let textSize = (text as NSString).size(withAttributes: attrs)
    let padH: CGFloat = 8
    let padV: CGFloat = 3
    let badgeWidth = textSize.width + padH * 2
    let badgeHeight = textSize.height + padV * 2
    let rect = CGRect(x: origin.x, y: origin.y, width: badgeWidth, height: badgeHeight)
    pdfFillRect(rect, color: bgColor, cornerRadius: badgeHeight / 2)
    (text as NSString).draw(
        at: CGPoint(x: origin.x + padH, y: origin.y + padV),
        withAttributes: attrs
    )
    return badgeWidth
}

// MARK: - Separator line
func pdfDrawSeparator(at y: CGFloat, x: CGFloat = PDFLayout.marginH, width: CGFloat? = nil, color: UIColor = UIColor.separator, lineWidth: CGFloat = 0.5) {
    let w = width ?? PDFLayout.contentWidth
    let path = UIBezierPath()
    path.move(to: CGPoint(x: x, y: y))
    path.addLine(to: CGPoint(x: x + w, y: y))
    path.lineWidth = lineWidth
    color.setStroke()
    path.stroke()
}

// MARK: - Metric card
func pdfDrawMetricCard(
    in rect: CGRect,
    title: String, value: String,
    bgColor: UIColor = UIColor.systemGray6,
    accentColor: UIColor
) {
    pdfFillRect(rect, color: bgColor, cornerRadius: 10)
    pdfStrokeRect(rect, color: UIColor.separator.withAlphaComponent(0.4), lineWidth: 0.5, cornerRadius: 10)

    // Value (large)
    let valueFont = UIFont.systemFont(ofSize: 26, weight: .bold)
    let valueAttrs: [NSAttributedString.Key: Any] = [.font: valueFont, .foregroundColor: accentColor]
    let valueSize = (value as NSString).size(withAttributes: valueAttrs)
    let valueY = rect.midY - valueSize.height / 2 - 8
    (value as NSString).draw(
        at: CGPoint(x: rect.midX - valueSize.width / 2, y: valueY),
        withAttributes: valueAttrs
    )

    // Title (small, below)
    let titleFont = UIFont.systemFont(ofSize: 11, weight: .medium)
    let titleAttrs: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: UIColor.secondaryLabel]
    let titleSize = (title as NSString).size(withAttributes: titleAttrs)
    (title as NSString).draw(
        at: CGPoint(x: rect.midX - titleSize.width / 2, y: valueY + valueSize.height + 4),
        withAttributes: titleAttrs
    )
}

// MARK: - Image drawing
func pdfDrawImage(_ image: UIImage, in rect: CGRect, cornerRadius: CGFloat = 0, contentMode: UIView.ContentMode = .scaleAspectFill) {
    guard let ctx = UIGraphicsGetCurrentContext() else { return }
    ctx.saveGState()
    if cornerRadius > 0 {
        UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).addClip()
    } else {
        ctx.clip(to: rect)
    }
    let drawRect = aspectFitRect(for: image.size, in: rect, mode: contentMode)
    image.draw(in: drawRect)
    ctx.restoreGState()
}

private func aspectFitRect(for imageSize: CGSize, in rect: CGRect, mode: UIView.ContentMode) -> CGRect {
    guard imageSize.width > 0 && imageSize.height > 0 else { return rect }
    let scale: CGFloat
    if mode == .scaleAspectFill {
        scale = max(rect.width / imageSize.width, rect.height / imageSize.height)
    } else {
        scale = min(rect.width / imageSize.width, rect.height / imageSize.height)
    }
    let w = imageSize.width * scale
    let h = imageSize.height * scale
    return CGRect(
        x: rect.midX - w / 2,
        y: rect.midY - h / 2,
        width: w, height: h
    )
}

// MARK: - Header bar (coloured strip)
func pdfDrawHeaderBar(title: String, y: CGFloat, color: UIColor) {
    let rect = CGRect(x: 0, y: y, width: PDFLayout.pageWidth, height: 36)
    pdfFillRect(rect, color: color)
    pdfDrawText(
        title,
        in: CGRect(x: PDFLayout.marginH, y: y + 8, width: PDFLayout.contentWidth, height: 20),
        font: UIFont.systemFont(ofSize: 13, weight: .bold),
        color: .white,
        alignment: .left
    )
}

// MARK: - Table row
func pdfDrawTableRow(label: String, value: String, y: CGFloat, isAlt: Bool = false) {
    if isAlt {
        pdfFillRect(CGRect(x: PDFLayout.marginH, y: y, width: PDFLayout.contentWidth, height: 22), color: UIColor.systemGray6.withAlphaComponent(0.5))
    }
    let labelFont = UIFont.systemFont(ofSize: 11, weight: .medium)
    let valueFont = UIFont.systemFont(ofSize: 11)
    pdfDrawText(label, in: CGRect(x: PDFLayout.marginH + 4, y: y + 4, width: 120, height: 16), font: labelFont, color: .secondaryLabel)
    pdfDrawText(value, in: CGRect(x: PDFLayout.marginH + 130, y: y + 4, width: PDFLayout.contentWidth - 134, height: 16), font: valueFont, color: .label)
}

// MARK: - Gradient helper
func pdfDrawGradient(
    ctx: CGContext,
    from topColor: UIColor,
    to bottomColor: UIColor,
    in rect: CGRect
) {
    guard let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [topColor.cgColor, bottomColor.cgColor] as CFArray,
        locations: [0, 1]
    ) else { return }
    ctx.saveGState()
    ctx.clip(to: rect)
    ctx.drawLinearGradient(
        gradient,
        start: CGPoint(x: rect.midX, y: rect.minY),
        end: CGPoint(x: rect.midX, y: rect.maxY),
        options: []
    )
    ctx.restoreGState()
}
