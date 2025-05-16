//
//  ZLEditImageViewController+ZLStickerViewDelegate.swift
//  ZLImageEditor
//
//  Created by Rahmat Zulfikri on 10/05/25.
//

import UIKit

extension ZLEditImageViewController: ZLStickerViewDelegate {
    func stickerBeginOperation(_ sticker: ZLBaseStickerView) {
        
        stickersContainer.bringSubviewToFront(sticker)
        
        selectSticker(sticker: sticker)

        preStickerState = sticker.state
        
        setToolView(show: false)

        stickersContainer.subviews.forEach { view in
            if view !== sticker {
                (view as? ZLStickerViewAdditional)?.resetState()
                (view as? ZLStickerViewAdditional)?.gesIsEnabled = false
            }
        }
    }
    
    func stickerOnOperation(_ sticker: ZLBaseStickerView, panGes: UIPanGestureRecognizer) {
        let point = panGes.location(in: view)
    }
    
    func stickerEndOperation(_ sticker: ZLBaseStickerView, panGes: UIPanGestureRecognizer) {

        setToolView(show: true)
       
        var endState: ZLBaseStickertState? = sticker.state
        let point = panGes.location(in: view)

        editorManager.storeAction(.sticker(oldState: preStickerState, newState: endState))
        preStickerState = nil
        
        stickersContainer.subviews.forEach { view in
            (view as? ZLStickerViewAdditional)?.gesIsEnabled = true
        }
    }
    
    func stickerDidTap(_ sticker: ZLBaseStickerView) {
        stickersContainer.bringSubviewToFront(sticker)
        stickersContainer.subviews.forEach { view in
            if view !== sticker {
                (view as? ZLStickerViewAdditional)?.resetState()
            }
        }
        
        selectSticker(sticker: sticker)
    }
    
    func sticker(_ textSticker: ZLTextStickerView, editText text: String) {
        showInputTextVC(text, textColor: textSticker.textColor, font: textSticker.font, fillColor: textSticker.fillColor, fontSize: textSticker.fontSize) { text, textColor, font, image, fillColor, fontSize  in
            guard let image = image, !text.isEmpty else {
                textSticker.remove()
                return
            }
            
            guard textSticker.text != text || textSticker.textColor != textColor || textSticker.font != font else {
                return
            }
            textSticker.text = text
            textSticker.textColor = textColor
            textSticker.fillColor = fillColor
            textSticker.image = image
            textSticker.font = font
            textSticker.fontSize = fontSize
            let newSize = ZLTextStickerView.calculateSize(image: image)
            textSticker.changeSize(to: newSize)
        }
    }
}
