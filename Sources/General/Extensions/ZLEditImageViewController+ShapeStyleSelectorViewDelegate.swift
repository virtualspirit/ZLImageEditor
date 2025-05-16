//
//  ZLEditImageViewController+ShapeStyleSelectorViewDelegate.swift
//  ZLImageEditor
//
//  Created by Rahmat Zulfikri on 10/05/25.
//

import UIKit

extension ZLEditImageViewController: ShapeStyleSelectorViewDelegate {
    func didSelectStrokeColor(_ color: UIColor) {
        guard let currentSelectedSticker = currentSticker else { return }
        
        let oldState = currentSelectedSticker.state
        
        if currentSelectedSticker is ZLShapeView {
            (currentSelectedSticker as! ZLShapeView).strokeColor = color
        } else if currentSelectedSticker is ZLLineView {
            (currentSelectedSticker as! ZLLineView).color = color
        } else if currentSelectedSticker is ZLArrowView {
            (currentSelectedSticker as! ZLArrowView).color = color
        } else if currentSelectedSticker is ZLFreehandDrawView {
            (currentSelectedSticker as! ZLFreehandDrawView).color = color;
        }
        
        let newState = currentSelectedSticker.state
        editorManager.storeAction(.sticker(oldState: oldState, newState: newState))
    }

    func didSelectFillColor(_ color: UIColor) {
        guard let currentSelectedSticker = currentSticker else { return }
        
        let oldState = currentSelectedSticker.state

        if currentSelectedSticker is ZLShapeView {
            (currentSelectedSticker as! ZLShapeView).fillColor = color
        }
        
        let newState = currentSelectedSticker.state
        editorManager.storeAction(.sticker(oldState: oldState, newState: newState))
    }

    func didSelectStrokeWidth(_ width: CGFloat) {
        guard let currentSelectedSticker = currentSticker else { return }
        
        let oldState = currentSelectedSticker.state

        if currentSelectedSticker is ZLShapeView {
            (currentSelectedSticker as! ZLShapeView).lineWidth = width
        } else if currentSelectedSticker is ZLLineView {
            (currentSelectedSticker as! ZLLineView).lineWidth = width
        } else if currentSelectedSticker is ZLArrowView {
            (currentSelectedSticker as! ZLArrowView).lineWidth = width
        } else if currentSelectedSticker is ZLFreehandDrawView {
            (currentSelectedSticker as! ZLFreehandDrawView).lineWidth = width
        }
            
        let newState = currentSelectedSticker.state
        editorManager.storeAction(.sticker(oldState: oldState, newState: newState))
    }

    func didSelectStrokeStyle(_ style: String) {
        guard let currentSelectedSticker = currentSticker else { return }

        let oldState = currentSelectedSticker.state
        
        if let lineView = currentSelectedSticker as? ZLLineView {
            lineView.strokeStyle = style // Ini akan memicu didSet di ZLLineView -> setNeedsDisplay()
        } else if let arrowView = currentSelectedSticker as? ZLArrowView {
            arrowView.strokeStyle = style // Anda perlu menambahkan properti serupa ke ZLArrowView
        } else if let shapeView = currentSelectedSticker as? ZLShapeView {
            shapeView.strokeStyle = style // Dan ke ZLShapeView
        } else if let freehandView = currentSelectedSticker as? ZLFreehandDrawView {
            // ZLFreehandDrawView mungkin perlu logika serupa jika mendukung style garis
            // freehandView.strokeStyle = style
        }
        
        let newState = currentSelectedSticker.state
        editorManager.storeAction(.sticker(oldState: oldState, newState: newState))
    }
}
