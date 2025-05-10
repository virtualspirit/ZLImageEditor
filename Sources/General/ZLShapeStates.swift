//
//  ZLShapeStates.swift
//  ZLImageEditor
//
//  Created by Rahmat Zulfikri on 03/04/25.
//
import UIKit

public class ZLLineState: ZLBaseStickertState {
    let startPoint: CGPoint // Relative to bounds
    let endPoint: CGPoint   // Relative to bounds
    let color: UIColor
    let lineWidth: CGFloat

    public init(
        id: String = UUID().uuidString,
        startPoint: CGPoint,
        endPoint: CGPoint,
        color: UIColor,
        lineWidth: CGFloat,
        originScale: CGFloat,
        originAngle: CGFloat,
        originFrame: CGRect,
        gesScale: CGFloat,
        gesRotation: CGFloat,
        totalTranslationPoint: CGPoint
    ) {
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.color = color
        self.lineWidth = lineWidth
        // Note: Passing a placeholder UIImage to base, as it expects one, but we won't use it.
        // Alternatively, modify ZLBaseStickertState to make image optional or create a new base.
        super.init(
            id: id,
            image: UIImage(), // Placeholder
            originScale: originScale,
            originAngle: originAngle,
            originFrame: originFrame,
            gesScale: gesScale,
            gesRotation: gesRotation,
            totalTranslationPoint: totalTranslationPoint
        )
    }
}

public class ZLArrowState: ZLBaseStickertState {
    let startPoint: CGPoint
    let endPoint: CGPoint
    let color: UIColor
    let lineWidth: CGFloat
    let headSize: CGFloat

    public init(
        id: String = UUID().uuidString,
        startPoint: CGPoint,
        endPoint: CGPoint,
        color: UIColor,
        lineWidth: CGFloat,
        headSize: CGFloat,
        originScale: CGFloat,
        originAngle: CGFloat,
        originFrame: CGRect,
        gesScale: CGFloat,
        gesRotation: CGFloat,
        totalTranslationPoint: CGPoint
    ) {
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.color = color
        self.lineWidth = lineWidth
        self.headSize = headSize
        super.init(
            id: id,
            image: UIImage(), // Placeholder
            originScale: originScale,
            originAngle: originAngle,
            originFrame: originFrame,
            gesScale: gesScale,
            gesRotation: gesRotation,
            totalTranslationPoint: totalTranslationPoint
        )
    }
}

public class ZLShapeState: ZLBaseStickertState {
    var shapeType: ZLImageEditorConfiguration.ShapeType
    var bounds: CGRect // Relative shape bounds within the sticker frame
    var strokeColor: UIColor
    var fillColor: UIColor?
    var lineWidth: CGFloat
    var cornerRadius: CGFloat // Only for rectangle

     public init(
        id: String = UUID().uuidString,
        shapeType: ZLImageEditorConfiguration.ShapeType,
        bounds: CGRect,
        strokeColor: UIColor,
        fillColor: UIColor?,
        lineWidth: CGFloat,
        cornerRadius: CGFloat,
        originScale: CGFloat,
        originAngle: CGFloat,
        originFrame: CGRect,
        gesScale: CGFloat,
        gesRotation: CGFloat,
        totalTranslationPoint: CGPoint
    ) {
        self.shapeType = shapeType
        self.bounds = bounds
        self.strokeColor = strokeColor
        self.fillColor = fillColor
        self.lineWidth = lineWidth
        self.cornerRadius = cornerRadius
        super.init(
            id: id,
            image: UIImage(), // Placeholder
            originScale: originScale,
            originAngle: originAngle,
            originFrame: originFrame,
            gesScale: gesScale,
            gesRotation: gesRotation,
            totalTranslationPoint: totalTranslationPoint
        )
    }
}
