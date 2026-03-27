//
//  ZLFreehandDrawView.swift
//  ZLImageEditor
//
//  Created by Rahmat Zulfikri on 11/05/25.
//

import UIKit

class ZLFreehandDrawView: ZLBaseStickerView {
    // Public properties for modification
    public var color: UIColor {
        didSet {
            if oldValue != color {
                self.setNeedsDisplay() // Trigger redraw when color changes
            }
        }
    }

    public var lineWidth: CGFloat {
        didSet {
            if oldValue != lineWidth {
                self.setNeedsDisplay()
            }
        }
    }

    public var strokeStyle: ZLStrokeStyle = .solid {
        didSet {
            if oldValue != strokeStyle {
                self.setNeedsDisplay()
            }
        }
    }

    // Internal storage for path data
    private let bezierPath: UIBezierPath
    private let originalRatio: CGFloat

    override var state: ZLFreehandDrawState {
        return ZLFreehandDrawState(
            id: id,
            bezierPath: self.bezierPath,
            color: self.color,
            lineWidth: self.lineWidth,
            strokeStyle: self.strokeStyle,
            originalRatio: self.originalRatio,
            originScale: originScale,
            originAngle: originAngle,
            originFrame: originFrame,
            gesScale: gesScale,
            gesRotation: gesRotation,
            totalTranslationPoint: totalTranslationPoint
        )
    }

    init(state: ZLFreehandDrawState) {
        self.bezierPath = state.bezierPath
        self.color = state.color
        self.lineWidth = state.lineWidth
        self.originalRatio = state.originalRatio

        super.init(
            id: state.id,
            originScale: state.originScale,
            originAngle: state.originAngle,
            originFrame: state.originFrame,
            gesScale: state.gesScale,
            gesRotation: state.gesRotation,
            totalTranslationPoint: state.totalTranslationPoint,
            showBorder: true
        )
        self.strokeStyle = state.strokeStyle
        self.clipsToBounds = false
        self.backgroundColor = .clear
        self.isOpaque = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()

        self.color.setStroke() // Use the view's current color property
        
        // The lineWidth for UIBezierPath needs to be the "model" width.
        // The view's transform (originScale, gesScale) will visually scale it.
        // So, if self.lineWidth is intended to be the visual width on screen at 1x sticker scale,
        // we might need to divide it by current effective scale of the sticker itself IF
        // self.lineWidth is meant to be the final visual thickness.
        // However, it's usually simpler if self.lineWidth is the "model" thickness,
        // and the view's scaling handles the visual part.
        // Let's assume self.lineWidth is the model thickness for now.
        let path = self.bezierPath.copy() as! UIBezierPath
        path.lineWidth = self.lineWidth
        path.lineJoinStyle = .round

        switch self.strokeStyle {
        case .dashed:
            let dashPattern: [CGFloat] = [lineWidth * 2, lineWidth * 1.5]
            path.setLineDash(dashPattern, count: dashPattern.count, phase: 0)
            path.lineCapStyle = .butt
        case .dotted:
            let dotPattern: [CGFloat] = [0, lineWidth * 1.5]
            path.setLineDash(dotPattern, count: dotPattern.count, phase: 0)
            path.lineCapStyle = .round
        case .solid:
            path.lineCapStyle = .round
        }

        path.stroke()

        context.restoreGState()
    }

    // Optional: Implement more precise hit-testing if needed
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard self.point(inside: point, with: event) else { return nil }

        // Consider current visual line width for hit testing
        // gesScale and originScale affect the visual size from the model lineWidth
        let visualLineWidth = self.lineWidth * gesScale * originScale
        let hitTestWidth = max(visualLineWidth, 15) // Make tappable area at least 15 points wide

        let hitPath = self.bezierPath.cgPath.copy(strokingWithWidth: hitTestWidth, lineCap: .round, lineJoin: .round, miterLimit: 0)
        
        if hitPath.contains(point) {
            return self
        }
        
        return nil
    }
}
