//
//  ZLFreehandDrawState.swift
//  ZLImageEditor
//
//  Created by Rahmat Zulfikri on 11/05/25.
//

import UIKit

public class ZLFreehandDrawState: ZLBaseStickertState {
    // Store the raw UIBezierPath from the ZLDrawPath
    let bezierPath: UIBezierPath
    let color: UIColor // Current color of the stroke
    let lineWidth: CGFloat // Current line width of the stroke

    // The original ZLDrawPath.ratio and defaultLinePath might still be useful
    // if you ever need to reconstruct the original drawing conditions or scale.
    let originalRatio: CGFloat // From ZLDrawPath

    public init(
        id: String = UUID().uuidString,
        bezierPath: UIBezierPath, // This is the path with points relative to its padded bounding box
        color: UIColor,
        lineWidth: CGFloat,
        originalRatio: CGFloat,
        originScale: CGFloat,
        originAngle: CGFloat,
        originFrame: CGRect,
        gesScale: CGFloat,
        gesRotation: CGFloat,
        totalTranslationPoint: CGPoint
    ) {
        self.bezierPath = bezierPath
        self.color = color
        self.lineWidth = lineWidth
        self.originalRatio = originalRatio

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
