//
//  ZLLineView.swift
//  ZLImageEditor
//
//  Created by Rahmat Zulfikri on 03/04/25.
//

import UIKit

class ZLLineView: ZLBaseStickerView {
    var startPoint: CGPoint // Relative to bounds
    var endPoint: CGPoint   // Relative to bounds
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
                self.setNeedsDisplay() // Trigger redraw when color changes
            }
        }
    }
    public var strokeStyle: String { // Bisa juga non-optional dengan default
        didSet {
            if oldValue != strokeStyle {
                self.setNeedsDisplay()
            }
        }
    }

    // Define a tolerance for tapping near the line
    private let tapTolerance: CGFloat = 0.0 // Adjust as needed (larger makes it easier to tap)

    // ... (state property and init remain the same, including setting borderWidth = 0) ...
   
    override var state: ZLLineState {
        return ZLLineState(
            id: id,
            startPoint: startPoint,
            endPoint: endPoint,
            color: color,
            lineWidth: lineWidth,
            originScale: originScale,
            originAngle: originAngle,
            originFrame: originFrame,
            gesScale: gesScale,
            gesRotation: gesRotation,
            totalTranslationPoint: totalTranslationPoint,
            strokeStyle: strokeStyle
        )
    }

    init(state: ZLLineState) {
        self.startPoint = state.startPoint
        self.endPoint = state.endPoint
        self.color = state.color
        self.lineWidth = state.lineWidth
        self.strokeStyle = state.strokeStyle
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
        self.backgroundColor = .clear
        self.contentMode = .redraw
        self.layer.borderWidth = 1// Ensure no visual border
    }

     required init?(coder: NSCoder) {
         fatalError("init(coder:) has not been implemented")
     }

    // ... (draw(_:) method remains the same) ...
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()

        let path = UIBezierPath()
        path.move(to: startPoint)
        path.addLine(to: endPoint)

        path.lineWidth = self.lineWidth
        path.lineJoinStyle = .round
        
        switch self.strokeStyle {
            case "dashed":
            let dashPattern: [CGFloat] = [lineWidth * 2, lineWidth * 1.5]
                path.setLineDash(dashPattern, count: dashPattern.count, phase: 0)
                path.lineCapStyle = .butt
            case "dotted":
                // Pola: panjang garis (0 untuk titik), panjang spasi
                let dotPattern: [CGFloat] = [0, lineWidth * 1.5] // Spasi antar titik
                path.setLineDash(dotPattern, count: dotPattern.count, phase: 0)
                path.lineCapStyle = .round // .round penting untuk membuat titik terlihat bundar
            case "solid":
                fallthrough // Jatuh ke default jika "Solid"
            default: // Solid
                path.lineCapStyle = .round // Ujung membulat untuk garis solid (atau .butt jika lebih disukai)
        }
        
        self.color.setStroke()
        path.stroke()

        context.restoreGState()
    }


    // MARK: - Precise Hit Testing
   override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
       guard self.point(inside: point, with: event) else {
           return nil
       }

       let path = UIBezierPath()
       path.move(to: startPoint)
       path.addLine(to: endPoint)

       let hitWidth = max(self.lineWidth, 10) + tapTolerance

       let hitPath = path.cgPath.copy(strokingWithWidth: hitWidth, lineCap: .round, lineJoin: .round, miterLimit: 0)

       if hitPath.contains(point) {
            return self
       }

       return nil
   }
   // Override point(inside:) to allow hitTest to be called even slightly outside original bounds
   override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
       // Check bounds expanded by the tap tolerance
       let expandedBounds = self.bounds.insetBy(dx: -tapTolerance, dy: -tapTolerance)
       return expandedBounds.contains(point)
   }
}
