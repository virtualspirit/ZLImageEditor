//
//  ZLEditImageViewController+UIGestureRecognizerDelegate.swift
//  ZLImageEditor
//
//  Created by Rahmat Zulfikri on 10/05/25.
//

import UIKit

extension ZLEditImageViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard imageStickerContainerIsHidden, fontChooserContainerIsHidden else {
            return false
        }
        if gestureRecognizer is UITapGestureRecognizer {
            if bottomShadowView.alpha == 1 {
                let p = gestureRecognizer.location(in: view)
                let convertP = bottomShadowView.convert(p, from: view)
                for subview in bottomShadowView.subviews {
                    if !subview.isHidden,
                       subview.alpha != 0,
                       subview.frame.contains(convertP) {
                        return false
                    }
                }
                return true
            } else {
                return true
            }
        } else if gestureRecognizer is UIPanGestureRecognizer {
            guard let st = selectedTool else {
                return false
            }
            return (st == .draw || st == .mosaic || selectedTool == .line || selectedTool == .arrow || selectedTool == .square || selectedTool == .circle) && !isScrolling
        }
        

        // Ensure default panGes for draw/mosaic doesn't fire when shape tools active
        if gestureRecognizer == panGes {
            return (selectedTool == .draw || selectedTool == .mosaic || selectedTool == .line || selectedTool == .arrow || selectedTool == .square || selectedTool == .circle) && !isScrolling
        }
                
        return true
    }
}
