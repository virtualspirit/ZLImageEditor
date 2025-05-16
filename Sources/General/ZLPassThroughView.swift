//
//  Untitled.swift
//  ZLImageEditor
//
//  Created by Rahmat Zulfikri on 10/05/25.
//

import UIKit

// MARK: 手势可透传的自定义view

public class ZLPassThroughView: UIView {
    var findResponderSticker: ((CGPoint) -> UIView?)?
    
    override public func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard bounds.contains(point) else {
            return super.hitTest(point, with: event)
        }
        
        for view in subviews.reversed() {
            let point = convert(point, to: view)
            if !view.isHidden,
               view.alpha != 0,
               view.bounds.contains(point) {
                return view.hitTest(point, with: event)
            }
        }
        
        if let sticker = findResponderSticker?(convert(point, to: superview)) {
            return sticker.hitTest(point, with: event)
        }
        
        return super.hitTest(point, with: event)
    }
}

