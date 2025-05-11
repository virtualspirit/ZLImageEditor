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
                (sticker as! ZLShapeView).strokeColor = color
            } else if sticker is ZLLineView {
                (sticker as! ZLLineView).color = color
            } else if sticker is ZLArrowView {
                (sticker as! ZLArrowView).color = color
            } else if sticker is ZLFreehandDrawView {
                (sticker as! ZLFreehandDrawView).color = color;
            }
        }
    }

    func didSelectFillColor(_ color: UIColor) {
        if let sticker = currentSticker {
            if sticker is ZLShapeView {
                (sticker as! ZLShapeView).fillColor = color
            }
        }
    }

    func didSelectStrokeWidth(_ width: CGFloat) {
        if let sticker = currentSticker {
            if sticker is ZLShapeView {
                (sticker as! ZLShapeView).lineWidth = width
            } else if sticker is ZLLineView {
                (sticker as! ZLLineView).lineWidth = width
            } else if sticker is ZLArrowView {
                (sticker as! ZLArrowView).lineWidth = width
            } else if sticker is ZLFreehandDrawView {
                (sticker as! ZLFreehandDrawView).lineWidth = width
            }
        }
    }

    func didSelectStrokeStyle(_ style: String) {
//        (currentSticker as? ZLShapeView)?.strokeStyle = style
    }
}
