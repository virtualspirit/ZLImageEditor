//
//  ZLEditImageViewController+ShapeStyleSelectorViewDelegate.swift
//  ZLImageEditor
//
//  Created by Rahmat Zulfikri on 10/05/25.
//

import UIKit

extension ZLEditImageViewController: ShapeStyleSelectorViewDelegate {
    func didSelectStrokeColor(_ color: UIColor) {
        if let sticker = currentSticker {
            if sticker is ZLShapeView {
                (sticker as! ZLShapeView).updateStrokeColor(color)
            } else if sticker is ZLLineView {
                (sticker as! ZLLineView).updateStrokeColor(color)
            } else if sticker is ZLArrowView {
                (sticker as! ZLArrowView).updateStrokeColor(color)
            }
        }
    }

    func didSelectFillColor(_ color: UIColor) {
        if let sticker = currentSticker {
            if sticker is ZLShapeView {
                (sticker as! ZLShapeView).updateFillColor(color)
            }
        }
    }

    func didSelectStrokeWidth(_ width: CGFloat) {
//        (currentSticker as? ZLShapeView)?.strokeWidth = width
    }

    func didSelectStrokeStyle(_ style: String) {
//        (currentSticker as? ZLShapeView)?.strokeStyle = style
    }
}
