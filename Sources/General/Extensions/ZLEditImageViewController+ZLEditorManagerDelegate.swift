//
//  ZLEditImageViewController+ZLEditorManagerDelegate.swift
//  ZLImageEditor
//
//  Created by Rahmat Zulfikri on 10/05/25.
//

// MARK: unod & redo
extension ZLEditImageViewController: ZLEditorManagerDelegate {
    func editorManager(_ manager: ZLEditorManager, didUpdateActions actions: [ZLEditorAction], redoActions: [ZLEditorAction]) {
        undoBtn.isEnabled = !actions.isEmpty
        redoBtn.isEnabled = actions.count != redoActions.count
    }
    
    func editorManager(_ manager: ZLEditorManager, undoAction action: ZLEditorAction) {
        switch action {
        case let .draw(path):
            undoDraw(path)
        case let .clip(oldStatus, _):
            undoOrRedoClip(oldStatus)
        case let .sticker(oldState, newState):
            undoSticker(oldState, newState)
        case let .mosaic(path):
            undoMosaic(path)
        case let .filter(oldFilter, _):
            undoOrRedoFilter(oldFilter)
        case let .adjust(oldStatus, _):
            undoOrRedoAdjust(oldStatus)
        }
    }
    
    func editorManager(_ manager: ZLEditorManager, redoAction action: ZLEditorAction) {
        switch action {
        case let .draw(path):
            redoDraw(path)
        case let .clip(_, newStatus):
            undoOrRedoClip(newStatus)
        case let .sticker(oldState, newState):
            redoSticker(oldState, newState)
        case let .mosaic(path):
            redoMosaic(path)
        case let .filter(_, newFilter):
            undoOrRedoFilter(newFilter)
        case let .adjust(_, newStatus):
            undoOrRedoAdjust(newStatus)
        }
    }
    
    private func undoDraw(_ path: ZLDrawPath) {
        drawPaths.removeLast()
        drawLine()
    }
    
    private func redoDraw(_ path: ZLDrawPath) {
        drawPaths.append(path)
        drawLine()
    }
    
    private func undoOrRedoClip(_ status: ZLClipStatus) {
        clipImage(status: status)
        preClipStatus = status
    }
    
    private func undoMosaic(_ path: ZLMosaicPath) {
        mosaicPaths.removeLast()
        generateNewMosaicImage()
    }
    
    private func redoMosaic(_ path: ZLMosaicPath) {
        mosaicPaths.append(path)
        generateNewMosaicImage()
    }
    
    private func undoSticker(_ oldState: ZLBaseStickertState?, _ newState: ZLBaseStickertState?) {
        // If oldState is nil, it was a creation. Undo is removing the 'newState' sticker.
        if oldState == nil, let stateToEffectivelyRemove = newState { // This matches undoing a creation/duplication
            removeStickerViewWithID(stateToEffectivelyRemove.id)
        }
        
        // If newState is nil, it was a removal. Undo is re-adding the 'oldState' sticker.
        else if newState == nil, let stateToReAdd = oldState {
           if let sticker = ZLBaseStickerView.initWithState(stateToReAdd) {
               addStickerToViewHierarchy(sticker) // Just add to view, don't store new undo action
               selectSticker(sticker: sticker) // Optionally re-select
           }
        }
        // If both are non-nil, it was a modification. Undo is applying oldState.
        else if let stateToApply = oldState, let currentState = newState {
            removeStickerViewWithID(currentState.id) // Remove current visual
           if let sticker = ZLBaseStickerView.initWithState(stateToApply) {
               addStickerToViewHierarchy(sticker)
               selectSticker(sticker: sticker) // Optionally re-select
           }
        }
    }
    
    private func redoSticker(_ oldState: ZLBaseStickertState?, _ newState: ZLBaseStickertState?) {
        // If newState is nil, it was a removal. Redo is removing the 'oldState' sticker again.
        if newState == nil, let stateToEffectivelyRemove = oldState {
            removeStickerViewWithID(stateToEffectivelyRemove.id)
            currentSticker = nil // Ensure it's deselected
        }
        // If oldState is nil, it was a creation. Redo is re-adding the 'newState' sticker.
        else if oldState == nil, let stateToReAdd = newState {
            if let sticker = ZLBaseStickerView.initWithState(stateToReAdd) {
                addStickerToViewHierarchy(sticker)
                selectSticker(sticker: sticker) // Optionally re-select
            }
        }
        // If both are non-nil, it was a modification. Redo is applying newState.
        else if let originalState = oldState, let stateToApply = newState {
            removeStickerViewWithID(originalState.id) // Remove current visual
            if let sticker = ZLBaseStickerView.initWithState(stateToApply) {
                addStickerToViewHierarchy(sticker)
                selectSticker(sticker: sticker) // Optionally re-select
            }
        }
    }
    
    private func undoOrRedoFilter(_ filter: ZLFilter?) {
        guard let filter else { return }
        changeFilter(filter)
        
        let filters = ZLImageEditorConfiguration.default().filters
        
        guard let filterCollectionView,
              let index = filters.firstIndex(where: { $0.name == filter.name }) else {
            return
        }
        
        let indexPath = IndexPath(row: index, section: 0)
        filterCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
        filterCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        filterCollectionView.reloadData()
    }
    
    private func undoOrRedoAdjust(_ status: ZLAdjustStatus) {
        var adjustTool: ZLImageEditorConfiguration.AdjustTool?
        
        if currentAdjustStatus.brightness != status.brightness {
            adjustTool = .brightness
        } else if currentAdjustStatus.contrast != status.contrast {
            adjustTool = .contrast
        } else if currentAdjustStatus.saturation != status.saturation {
            adjustTool = .saturation
        }
        
        currentAdjustStatus = status
        preAdjustStatus = status
        adjustStatusChanged()
        
        guard let adjustTool else { return }
        
        changeAdjustTool(adjustTool)
        
        guard let adjustCollectionView,
              let index = adjustTools.firstIndex(where: { $0 == adjustTool }) else {
            return
        }
        
        let indexPath = IndexPath(row: index, section: 0)
        adjustCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
        adjustCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        adjustCollectionView.reloadData()
    }
    
    // Helper to remove a sticker view by ID without creating an undo action itself
    func removeStickerViewWithID(_ id: String) {
        for view in stickersContainer.subviews {
            if let sticker = view as? ZLBaseStickerView, sticker.id == id {
                sticker.removeFromSuperview()
                // If this was the selected sticker, deselect it
                if currentSticker === sticker {
                    currentSticker = nil
                }
                break
            }
        }
    }

    // Helper to add a sticker to view hierarchy without creating an undo action
    // This is used by undo/redo logic.
    func addStickerToViewHierarchy(_ sticker: ZLBaseStickerView) {
        // Ensure no duplicate sticker with the same ID exists from a previous state
        removeStickerViewWithID(sticker.id)
        
        stickersContainer.addSubview(sticker)
        sticker.frame = sticker.originFrame // Set its initial frame from its state
        configSticker(sticker) // Re-apply delegate and gesture recognizer requirements
        // DO NOT call editorManager.storeAction here, as this is part of an undo/redo
    }
}
