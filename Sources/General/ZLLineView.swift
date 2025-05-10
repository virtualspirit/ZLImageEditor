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
    var color: UIColor
    var lineWidth: CGFloat

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
            totalTranslationPoint: totalTranslationPoint
        )
    }

    init(state: ZLLineState) {
        self.startPoint = state.startPoint
        self.endPoint = state.endPoint
        self.color = state.color
        self.lineWidth = state.lineWidth
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
        path.lineCapStyle = .round
        path.lineJoinStyle = .round

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
       // MARK: - CORRECTED - No 'if let' needed here
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
