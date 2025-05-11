//
//  ZLShapeView.swift
//  ZLImageEditor
//
//  Created by Rahmat Zulfikri on 03/04/25.
//

import UIKit

class ZLShapeView: ZLBaseStickerView {
    var shapeType: ZLImageEditorConfiguration.ShapeType
    var shapeBounds: CGRect // Relative bounds within the sticker's frame
    public var strokeColor: UIColor {
        didSet {
            if oldValue != strokeColor {
                self.setNeedsDisplay() // Trigger redraw when color changes
            }
        }
    }
    
    public var fillColor: UIColor? {
        didSet {
            let originalOldValue = oldValue

            if fillColor == UIColor.clear {
                self.fillColor = nil
            }

            if originalOldValue != self.fillColor {
                self.setNeedsDisplay()
            }
        }
    }
    
    public var lineWidth: CGFloat {
        didSet {
            if oldValue != lineWidth {
                self.setNeedsDisplay() // Trigger redraw when color changes
            }
        }
    }
    
    var cornerRadius: CGFloat

    // Increased tolerance for shapes, especially if only stroked
    private let tapTolerance: CGFloat = 0.0

    // ... (state property and init remain the same, including setting borderWidth = 0) ...
    override var state: ZLShapeState {
        return ZLShapeState(
            // ... properties ...
            id: id,
            shapeType: shapeType,
            bounds: shapeBounds, // Use shapeBounds here
            strokeColor: strokeColor,
            fillColor: fillColor,
            lineWidth: lineWidth,
            cornerRadius: cornerRadius,
            originScale: originScale,
            originAngle: originAngle,
            originFrame: originFrame,
            gesScale: gesScale,
            gesRotation: gesRotation,
            totalTranslationPoint: totalTranslationPoint
        )
    }

    init(state: ZLShapeState) {
        // ... initialize properties ...
        self.shapeType = state.shapeType
        self.shapeBounds = state.bounds
        self.strokeColor = state.strokeColor
        self.fillColor = state.fillColor
        self.lineWidth = state.lineWidth
        self.cornerRadius = state.cornerRadius
        super.init( /* ... base properties from state ... */
             id: state.id,
             originScale: state.originScale,
             originAngle: state.originAngle,
             originFrame: state.originFrame,
             gesScale: state.gesScale,
             gesRotation: state.gesRotation,
             totalTranslationPoint: state.totalTranslationPoint,
             showBorder: true
        )
        self.backgroundColor = .clear
        self.contentMode = .redraw
        self.layer.borderWidth = 1 // Ensure no visual border
    }

    required init?(coder: NSCoder) {
         fatalError("init(coder:) has not been implemented")
     }

    // ... (draw(_:) method remains the same) ...
    override func draw(_ rect: CGRect) {
        // ... (draw shape based on type, fill, stroke) ...
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()

        let path: UIBezierPath
        switch shapeType {
        case .rectangle:
            if cornerRadius > 0 {
                path = UIBezierPath(roundedRect: shapeBounds, cornerRadius: cornerRadius)
            } else {
                path = UIBezierPath(rect: shapeBounds)
            }
        case .ellipse:
            path = UIBezierPath(ovalIn: shapeBounds)
        }

        if let fill = fillColor {
            fill.setFill()
            path.fill()
        }

        path.lineWidth = self.lineWidth
        self.strokeColor.setStroke()
        path.stroke()

        context.restoreGState()
    }


    // MARK: - Precise Hit Testing
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard self.point(inside: point, with: event) else {
            return nil
        }

        let path: UIBezierPath
        // ... (create path based on shapeType) ...
        switch shapeType {
        case .rectangle:
            if cornerRadius > 0 {
                path = UIBezierPath(roundedRect: shapeBounds, cornerRadius: cornerRadius)
            } else {
                path = UIBezierPath(rect: shapeBounds)
            }
        case .ellipse:
            path = UIBezierPath(ovalIn: shapeBounds)
        }


        if fillColor != nil {
            // Option 1: Simple contains check (usually fine for fills)
             if path.contains(point) { return self }

            // Option 2: Check with tolerance using stroked path (if needed near edge)
             let hitPathForFill = path.cgPath.copy(strokingWithWidth: tapTolerance, lineCap: .round, lineJoin: .round, miterLimit: 0)
             if hitPathForFill.contains(point) { return self }
        } else {
            // Only stroked shape
            let hitWidth = max(self.lineWidth, 10) + tapTolerance
            // MARK: - CORRECTED - No 'if let' needed here
            let hitPath = path.cgPath.copy(strokingWithWidth: hitWidth, lineCap: .round, lineJoin: .round, miterLimit: 0)

            if hitPath.contains(point) {
                return self
            }
        }

        return nil
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let expandedBounds = self.bounds.insetBy(dx: -tapTolerance, dy: -tapTolerance)
        return expandedBounds.contains(point)
    }
}
