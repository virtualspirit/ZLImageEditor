//
//  ZLArrowView.swift
//  ZLImageEditor
//
//  Created by Rahmat Zulfikri on 03/04/25.
//

import UIKit

class ZLArrowView: ZLBaseStickerView {
    var startPoint: CGPoint
    var endPoint: CGPoint
    var color: UIColor
    var lineWidth: CGFloat
    var headSize: CGFloat

    private let tapTolerance: CGFloat = 0.0

    // ... (state property and init remain the same, including setting borderWidth = 0) ...
    override var state: ZLArrowState {
        return ZLArrowState(
            // ... properties ...
            id: id,
            startPoint: startPoint,
            endPoint: endPoint,
            color: color,
            lineWidth: lineWidth,
            headSize: headSize,
            originScale: originScale,
            originAngle: originAngle,
            originFrame: originFrame,
            gesScale: gesScale,
            gesRotation: gesRotation,
            totalTranslationPoint: totalTranslationPoint
        )
    }
    
    init(state: ZLArrowState) {
        // ... initialize properties ...
        self.startPoint = state.startPoint
        self.endPoint = state.endPoint
        self.color = state.color
        self.lineWidth = state.lineWidth
        self.headSize = state.headSize
        super.init( /* ... base properties from state ... */
             id: state.id,
             originScale: state.originScale,
             originAngle: state.originAngle,
             originFrame: state.originFrame,
             gesScale: state.gesScale,
             gesRotation: state.gesRotation,
             totalTranslationPoint: state.totalTranslationPoint,
             showBorder: false
        )
        self.backgroundColor = .clear
        self.contentMode = .redraw
        self.layer.borderWidth = 0 // Ensure no visual border
    }

    required init?(coder: NSCoder) {
         fatalError("init(coder:) has not been implemented")
    }

    // ... (draw(_:) method remains the same) ...
    override func draw(_ rect: CGRect) {
         // ... (draw line and arrowhead) ...
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()

        // --- Draw Line ---
        let linePath = UIBezierPath()
        linePath.move(to: startPoint)
        linePath.addLine(to: endPoint)
        linePath.lineWidth = self.lineWidth
        linePath.lineCapStyle = .round
        linePath.lineJoinStyle = .round

        // --- Draw Arrow Head ---
        let headPath = UIBezierPath() // Path for the head only
        let arrowHeadAngleConfig = ZLImageEditorConfiguration.default().defaultArrowHeadAngleConfig
        
        let angle = atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x)
        let angle1 = angle + arrowHeadAngleConfig
        let angle2 = angle - arrowHeadAngleConfig

        headPath.move(to: CGPoint(x: endPoint.x + cos(angle1) * headSize, y: endPoint.y + sin(angle1) * headSize))
        headPath.addLine(to: endPoint)
        headPath.addLine(to: CGPoint(x: endPoint.x + cos(angle2) * headSize, y: endPoint.y + sin(angle2) * headSize))
        headPath.lineWidth = self.lineWidth
        headPath.lineCapStyle = .round
        headPath.lineJoinStyle = .round

        // Stroke line and head separately or combined as needed for visuals
        self.color.setStroke()
        linePath.stroke()
        headPath.stroke() // Stroke the head

        context.restoreGState()
    }


    // MARK: - Precise Hit Testing
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard self.point(inside: point, with: event) else {
            return nil
        }

        // ... (create linePath and headPath) ...
        let linePath = UIBezierPath()
        linePath.move(to: startPoint)
        linePath.addLine(to: endPoint)

        let arrowHeadAngleConfig = ZLImageEditorConfiguration.default().defaultArrowHeadAngleConfig
        let headPath = UIBezierPath()
         // ... (calculate arrowhead points) ...
         let angle = atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x)
         let angle1 = angle + arrowHeadAngleConfig
         let angle2 = angle - arrowHeadAngleConfig
         headPath.move(to: CGPoint(x: endPoint.x + cos(angle1) * headSize, y: endPoint.y + sin(angle1) * headSize))
         headPath.addLine(to: endPoint)
         headPath.addLine(to: CGPoint(x: endPoint.x + cos(angle2) * headSize, y: endPoint.y + sin(angle2) * headSize))


        let combinedCGPath = CGMutablePath()
        if let lineCG = linePath.cgPath.mutableCopy() { combinedCGPath.addPath(lineCG) }
        if let headCG = headPath.cgPath.mutableCopy() { combinedCGPath.addPath(headCG) }

        let hitWidth = max(self.lineWidth, 10) + tapTolerance
        // MARK: - CORRECTED - No 'if let' needed here
        let hitPath = combinedCGPath.copy(strokingWithWidth: hitWidth, lineCap: .round, lineJoin: .round, miterLimit: 0)

        if hitPath.contains(point) {
             return self
        }

        return nil
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let expandedBounds = self.bounds.insetBy(dx: -tapTolerance, dy: -tapTolerance)
        return expandedBounds.contains(point)
    }
}
