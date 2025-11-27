//
//  EditorViewController+ToolsView.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/17.
//

import UIKit
import PencilKit

extension EditorViewController: EditorToolsViewDelegate {
    func toolsView(_ toolsView: EditorToolsView, didSelectItemAt model: EditorConfiguration.ToolsView.Options) {
        if editorView.type != .video, model.type == .time {
            return
        }
        editorView.deselectedSticker()
        switch model.type {
        case .graffiti:
            if #available(iOS 13.0, *), editorView.drawType == .canvas {
                hideLastToolView()
                hideToolsView(isCanvasGraffiti: true)
                selectedTool = model
                showCanvasViews()
                editorView.isStickerEnabled = false
                startCanvasDrawing()
                updateBottomMaskLayer()
                lastSelectedTool = model
                return
            }else {
                selectedTool = model
            }
        case .text:
            presentText()
            return
        case .chartlet:
            let vc = config.chartlet.listProtcol.init(config: config, editorType: selectedAsset.contentType)
            if let vc = vc as? EditorChartletViewController {
                vc.chartletDelegate = self
            }
            vc.modalPresentationStyle = config.chartlet.modalPresentationStyle
            vc.delegate = self
            present(vc, animated: true)
            return
        default:
            selectedTool = model
        }
        hideLastToolView()
        switch model.type {
        case .graffiti:
            editorView.isStickerEnabled = false
            editorView.isDrawEnabled = true
            showBrushColorView()
        case .mosaic:
            editorView.isStickerEnabled = false
            editorView.isMosaicEnabled = true
            showMosaicToolView()
        case .filter:
            showFiltersView()
        case .music:
            showMusicView()
            return
        case .cropSize:
            if let selectType = scaleSwitchSelectType {
                scaleSwitchLeftBtn.isSelected = selectType == 0
                scaleSwitchRightBtn.isSelected = selectType == 1
            }
            editorView.startEdit(true) { [weak self] in
                guard let self = self else {
                    return
                }
                if let ratio = self.ratioToolView.selectedRatio?.ratio, !ratio.equalTo(.zero), !self.editorView.isRoundMask {
                    self.ratioToolView(self.ratioToolView, didSelectedRatioAt: ratio)
                }
            }
            showCropSizeToolsView()
            checkFinishButtonState()
            return
        case .time:
            showVideoControlView()
        case .filterEdit:
            showFilterEditView()
        case .mainImage:
            showMainImageView()
        default:
            break
        }
        lastSelectedTool = model
        updateBottomMaskLayer()
    }
    
    func toolsView(_ toolsView: EditorToolsView, deselectItemAt model: EditorConfiguration.ToolsView.Options) {
        lastSelectedTool = nil
        selectedTool = nil
        switch model.type {
        case .time:
            hideVideoControlView()
        case .graffiti:
            editorView.isDrawEnabled = false
            hideBrushColorView()
        case .mosaic:
            editorView.isMosaicEnabled = false
            hideMosaicToolView()
        case .filter:
            hideFiltersView()
        case .filterEdit:
            hideFilterEditView()
        case .mainImage:
            hideMainImageView()
        default:
            break
        }
        editorView.isStickerEnabled = true
        updateBottomMaskLayer()
    }
    
    func showToolsView() {
        if !toolsView.isHidden && toolsView.alpha == 1 {
            return
        }
        if let tool = selectedTool, tool.type == .graffiti, editorView.drawType == .canvas {
            return
        }
        toolsView.isHidden = false
        // ✅ 非裁剪模式：保持底部按钮隐藏，使用顶部按钮
        // cancelButton.isHidden = false
        // finishButton.isHidden = false
        topMaskView.isHidden = false
        bottomMaskView.isHidden = false
        UIView.animate(withDuration: 0.2) {
            self.toolsView.alpha = 1
            // ✅ 非裁剪模式：保持底部按钮隐藏
            // self.cancelButton.alpha = 1
            // self.finishButton.alpha = 1
            if !UIDevice.isPortrait || self.config.buttonType == .top {
                self.topMaskView.alpha = 1
            }
            self.bottomMaskView.alpha = 1
        }
        if let selectedTool = selectedTool {
            switch selectedTool.type {
            case .time:
                showVideoControlView()
            case .graffiti:
                showBrushColorView()
            case .mosaic:
                showMosaicToolView()
            case .filter:
                showFiltersView()
            case .filterEdit:
                showFilterEditView()
            case .mainImage:
                showMainImageView()
            default:
                break
            }
        }
    }

    func hideToolsView(isCanvasGraffiti: Bool = false) {
        if toolsView.isHidden || toolsView.alpha == 0 {
            return
        }
        if let selectedTool = selectedTool {
            switch selectedTool.type {
            case .time:
                hideVideoControlView()
            case .graffiti:
                hideBrushColorView()
            case .mosaic:
                hideMosaicToolView()
            case .filter:
                hideFiltersView()
            case .filterEdit:
                hideFilterEditView()
            case .mainImage:
                hideMainImageView()
            default:
                break
            }
        }
        UIView.animate(withDuration: 0.2) {
            self.toolsView.alpha = 0
            // ✅ 非裁剪模式：保持底部按钮隐藏
            // self.cancelButton.alpha = 0
            // self.finishButton.alpha = 0
            if !isCanvasGraffiti {
                self.topMaskView.alpha = 0
            }
            self.bottomMaskView.alpha = 0
        } completion: {
            if $0 {
                self.toolsView.isHidden = true
                // ✅ 非裁剪模式：保持底部按钮隐藏
                // self.cancelButton.isHidden = true
                // self.finishButton.isHidden = true
                if !isCanvasGraffiti {
                    self.topMaskView.isHidden = true
                }
                self.bottomMaskView.isHidden = true
            }
        }
    }
    
    func hideLastToolView() {
        if let selectedTool = selectedTool {
            switch selectedTool.type {
            case .text, .chartlet:
                return
            default:
                break
            }
        }
        if let lastSelectedTool = lastSelectedTool {
            switch lastSelectedTool.type {
            case .time:
                hideVideoControlView()
            case .graffiti:
                editorView.isStickerEnabled = true
                editorView.isDrawEnabled = false
                hideBrushColorView()
            case .mosaic:
                editorView.isStickerEnabled = true
                editorView.isMosaicEnabled = false
                hideMosaicToolView()
            case .filter:
                hideFiltersView()
            case .filterEdit:
                hideFilterEditView()
            case .mainImage:
                hideMainImageView()
            default:
                break
            }
        }
    }
    
    func showLastToolView() {
        if let lastSelectedTool = lastSelectedTool {
            switch lastSelectedTool.type {
            case .time:
                showVideoControlView()
            case .graffiti:
                showBrushColorView()
            case .mosaic:
                showMosaicToolView()
            case .filter:
                showFiltersView()
            case .filterEdit:
                showFilterEditView()
            case .mainImage:
                showMainImageView()
            default:
                break
            }
        }
    }
    
    func showVideoControlView() {
        if !videoControlView.isHidden && videoControlView.alpha == 1 {
            return
        }
        videoControlView.isHidden = false
        UIView.animate(withDuration: 0.2) {
            self.videoControlView.alpha = 1
        }
    }
    
    func hideVideoControlView() {
        if videoControlView.isHidden || videoControlView.alpha == 0 {
            return
        }
        videoControlView.stopScroll()
        UIView.animate(withDuration: 0.2) {
            self.videoControlView.alpha = 0
        } completion: {
            if $0 {
                self.videoControlView.isHidden = true
            }
        }
    }
    
    @available(iOS 13.0, *)
    func startCanvasDrawing(_ isRotate: Bool = false) {
        let toolPicker: PKToolPicker
        if isRotate {
            guard let _toolPicker = editorView.enterCanvasDrawing() else {
                return
            }
            toolPicker = _toolPicker
        }else {
            guard let _toolPicker = editorView.startCanvasDrawing() else {
                return
            }
            toolPicker = _toolPicker
        }
        editorView.setZoomScale(1, animated: true)
        editorView.setContentOffset(.zero, animated: true)
        
        let topHeight = topMaskView.height
        let rect = toolPicker.frameObscured(in: view)
        let maxHeight: CGFloat
        if rect.isNull {
            let bottomMargin: CGFloat
            if isFullScreen {
                bottomMargin = UIDevice.bottomMargin + 10
            }else {
                bottomMargin = 20
            }
            maxHeight = view.height - topHeight - bottomMargin
        }else {
            maxHeight = rect.minY - topMaskView.height
        }
        let contentHeight = editorView.contentSize.height
        backgroundView.bouncesZoom = true
        editorView.isCanZoomScale = false
        backgroundView.maximumZoomScale = 20
        if contentHeight > maxHeight {
            let zoomScale = maxHeight / contentHeight
            let minWidth = view.width * zoomScale
            
            backgroundInsetRect = .init(x: (view.width - minWidth) / 2, y: topHeight, width: minWidth, height: maxHeight)
            let editorHeight = editorView.height * zoomScale
            if editorHeight < backgroundInsetRect.height, contentHeight > editorHeight {
                backgroundView.contentSize = editorView.contentSize
                editorView.height = contentHeight
            }
            backgroundView.minimumZoomScale = zoomScale
            UIView.animate {
                self.backgroundView.zoomScale = zoomScale
            }
        }else {
            backgroundView.minimumZoomScale = 1
            let padding = (maxHeight - contentHeight) / 2
            let top = topHeight + padding
            backgroundInsetRect = .init(x: 0, y: top, width: view.width, height: contentHeight)
            let offsetY = (view.height - contentHeight) / 2 - top
            UIView.animate {
                self.backgroundView.contentOffset = .init(x: 0, y: offsetY)
            }
        }
    }
    
    func showCanvasViews() {
        if editorView.drawType != .canvas {
            return
        }
        if !drawCancelButton.isHidden && drawCancelButton.alpha == 1 {
            return
        }
        
        // ✅ 进入Canvas画笔模式：隐藏顶部按钮
        backButton.isHidden = true
        shareButton.isHidden = true
        saveButton.isHidden = true
        
        editorView.hideStickersView()
        drawCancelButton.isHidden = false
        drawFinishButton.isHidden = false
        drawUndoBtn.isHidden = false
        drawRedoBtn.isHidden = false
        drawUndoAllBtn.isHidden = false
        topMaskView.isHidden = false
        UIView.animate {
            self.drawCancelButton.alpha = 1
            self.drawFinishButton.alpha = 1
            self.drawUndoBtn.alpha = 1
            self.drawRedoBtn.alpha = 1
            self.drawUndoAllBtn.alpha = 1
            self.topMaskView.alpha = 1
        }
    }
    
    func hideCanvasViews(_ isRotate: Bool = false, animated: Bool = true) {
        if editorView.drawType != .canvas {
            return
        }
        if drawCancelButton.isHidden || drawCancelButton.alpha == 0 {
            return
        }
        
        // ✅ 退出Canvas画笔模式：显示顶部按钮
        backButton.isHidden = false
        shareButton.isHidden = false
        saveButton.isHidden = false
        
        if !isRotate {
            editorView.showStickersView()
            editorView.isCanZoomScale = true
        }else {
            backgroundInsetRect = view.bounds
        }
        backgroundView.contentSize = view.size
        if animated {
            UIView.animate  {
                self.backgroundView.zoomScale = 1
                self.scrollViewDidZoom(self.backgroundView)
                self.backgroundView.contentOffset = .zero
                self.editorView.zoomScale = 1
                self.drawCancelButton.alpha = 0
                self.drawFinishButton.alpha = 0
                self.drawUndoBtn.alpha = 0
                self.drawRedoBtn.alpha = 0
                self.drawUndoAllBtn.alpha = 0
                if self.config.buttonType == .bottom && UIDevice.isPortrait {
                    self.topMaskView.alpha = 0
                }
            } completion: {
                if $0 {
                    self.backgroundView.maximumZoomScale = 1
                    self.backgroundView.minimumZoomScale = 1
                    self.backgroundView.bouncesZoom = false
                    self.drawCancelButton.isHidden = true
                    self.drawFinishButton.isHidden = true
                    self.drawUndoBtn.isHidden = true
                    self.drawRedoBtn.isHidden = true
                    self.drawUndoAllBtn.isHidden = true
                    if self.config.buttonType == .bottom && UIDevice.isPortrait {
                        self.topMaskView.isHidden = true
                    }
                }
            }
        }else {
            self.backgroundView.zoomScale = 1
            self.scrollViewDidZoom(self.backgroundView)
            self.backgroundView.contentOffset = .zero
            self.backgroundView.maximumZoomScale = 1
            self.backgroundView.minimumZoomScale = 1
            self.backgroundView.bouncesZoom = false
            self.editorView.zoomScale = 1
            self.drawCancelButton.alpha = 0
            self.drawFinishButton.alpha = 0
            self.drawUndoBtn.alpha = 0
            self.drawRedoBtn.alpha = 0
            self.drawUndoAllBtn.alpha = 0
            if self.config.buttonType == .bottom && UIDevice.isPortrait {
                self.topMaskView.alpha = 0
            }
            self.drawCancelButton.isHidden = true
            self.drawFinishButton.isHidden = true
            self.drawUndoBtn.isHidden = true
            self.drawRedoBtn.isHidden = true
            self.drawUndoAllBtn.isHidden = true
            if self.config.buttonType == .bottom && UIDevice.isPortrait {
                self.topMaskView.isHidden = true
            }
        }
    }
    
    func showBrushColorView() {
        if editorView.drawType == .canvas {
            return
        }
        if !brushColorView.isHidden && brushColorView.alpha == 1 {
            return
        }
        
        // ✅ 进入普通画笔模式：隐藏顶部按钮
        backButton.isHidden = true
        shareButton.isHidden = true
        saveButton.isHidden = true
        
        brushColorView.isHidden = false
        brushSizeView.isHidden = false
        UIView.animate(withDuration: 0.2) {
            self.brushColorView.alpha = 1
            self.brushSizeView.alpha = 1
        }
    }
    
    func hideBrushColorView() {
        if brushColorView.isHidden || brushColorView.alpha == 0 {
            return
        }
        
        // ✅ 退出普通画笔模式：显示顶部按钮
        backButton.isHidden = false
        shareButton.isHidden = false
        saveButton.isHidden = false
        
        UIView.animate(withDuration: 0.2) {
            self.brushColorView.alpha = 0
            self.brushSizeView.alpha = 0
        } completion: {
            if $0 {
                self.brushColorView.isHidden = true
                self.brushSizeView.isHidden = true
            }
        }
    }
    
    func showMosaicToolView() {
        if !mosaicToolView.isHidden && mosaicToolView.alpha == 1 {
            return
        }
        
        // ✅ 进入马赛克模式：隐藏顶部按钮
        backButton.isHidden = true
        shareButton.isHidden = true
        saveButton.isHidden = true
        
        mosaicToolView.isHidden = false
        UIView.animate(withDuration: 0.2) {
            self.mosaicToolView.alpha = 1
        }
    }
    
    func hideMosaicToolView() {
        if mosaicToolView.isHidden || mosaicToolView.alpha == 0 {
            return
        }
        
        // ✅ 退出马赛克模式：显示顶部按钮
        backButton.isHidden = false
        shareButton.isHidden = false
        saveButton.isHidden = false
        
        UIView.animate(withDuration: 0.2) {
            self.mosaicToolView.alpha = 0
        } completion: {
            if $0 {
                self.mosaicToolView.isHidden = true
            }
        }
    }
    
    func showMusicView() {
        if musicView.y == view.height - musicView.height - UIDevice.bottomMargin {
            return
        }
        if let shouldClick = delegate?.editorViewController(shouldClickMusicTool: self),
           !shouldClick {
            return
        }
        editorView.isStickerEnabled = false
        hideToolsView()
        if musicView.musics.isEmpty {
            if let loadHandler = config.video.music.handler {
                let showLoading = loadHandler { [weak self] infos in
                    self?.musicView.reloadData(infos: infos)
                }
                if showLoading {
                    musicView.showLoading()
                }
            }else {
                if let editorDelegate = delegate {
                    if editorDelegate.editorViewController(
                        self,
                        loadMusic: { [weak self] infos in
                            self?.musicView.reloadData(infos: infos)
                    }) {
                        musicView.showLoading()
                    }
                }else {
                    let infos = PhotoTools.defaultMusicInfos()
                    if infos.isEmpty {
                        PhotoManager.HUDView.showInfo(with: .textManager.editor.music.emptyHudTitle.text, delay: 1.5, animated: true, addedTo: view)
                        return
                    }else {
                        musicView.reloadData(infos: infos)
                    }
                }
            }
        }
        UIView.animate(withDuration: 0.2) {
            self.updateMusicViewFrame()
        }
    }
    
    func hideMusicView() {
        if musicView.y == view.height {
            return
        }
        UIView.animate(withDuration: 0.2) {
            self.updateMusicViewFrame()
        }
    }
    
    func showFilterEditView() {
        if !filterEditView.isHidden && filterEditView.alpha == 1 {
            return
        }
        filterEditView.isHidden = false
        UIView.animate(withDuration: 0.2) {
            self.filterEditView.alpha = 1
        }
    }
    
    func hideFilterEditView() {
        if filterEditView.isHidden || filterEditView.alpha == 0 {
            return
        }
        UIView.animate(withDuration: 0.2) {
            self.filterEditView.alpha = 0
        } completion: {
            if $0 {
                self.filterEditView.isHidden = true
            }
        }
    }
    
    func showFiltersView() {
        if !filtersView.isHidden && filtersView.alpha == 1 {
            return
        }
        filtersView.isHidden = false
        UIView.animate(withDuration: 0.2) {
            self.filtersView.alpha = 1
        }
    }
    
    func hideFiltersView() {
        if filtersView.isHidden || filtersView.alpha == 0 {
            return
        }
        UIView.animate(withDuration: 0.2) {
            self.filtersView.alpha = 0
        } completion: {
            if $0 {
                self.filtersView.isHidden = true
            }
        }
    }
    
    func showCropSizeToolsView() {
        if !rotateScaleView.isHidden && rotateScaleView.alpha == 1 {
            return
        }
        if !config.cropSize.aspectRatios.isEmpty {
            ratioToolView.isHidden = false
        }
        rotateScaleView.isHidden = false
        resetButton.isHidden = false
        leftRotateButton.isHidden = false
        rightRotateButton.isHidden = false
        mirrorVerticallyButton.isHidden = false
        mirrorHorizontallyButton.isHidden = false
        
        // ✅ 进入裁剪模式：隐藏顶部按钮，显示底部按钮
        backButton.isHidden = true
        shareButton.isHidden = true
        saveButton.isHidden = true
        cancelButton.isHidden = false
        finishButton.isHidden = false
        
        var isShowMaskList: Bool = true
        if let ratio = ratioToolView.selectedRatio?.ratio, (ratio.width < 0 || ratio.height < 0) {
            isShowMaskList = false
        }
        if isShowMaskList {
            maskListButton.isHidden = false
        }
        showScaleSwitchView()
        UIView.animate(withDuration: 0.2) {
            if !self.config.cropSize.aspectRatios.isEmpty {
                self.ratioToolView.alpha = 1
            }
            self.rotateScaleView.alpha = 1
            self.resetButton.alpha = 1
            self.leftRotateButton.alpha = 1
            self.rightRotateButton.alpha = 1
            self.mirrorVerticallyButton.alpha = 1
            self.mirrorHorizontallyButton.alpha = 1
            if isShowMaskList {
                self.maskListButton.alpha = 1
            }
            // ✅ 进入裁剪模式：设置底部按钮可见
            self.cancelButton.alpha = 1
            self.finishButton.alpha = 1
            self.toolsView.alpha = 0
            self.hideMasks()
        } completion: {
            if $0 {
                self.toolsView.isHidden = true
            }
        }
    }
    
    func hideCropSizeToolsView() {
        showLastToolView()
        selectedTool = lastSelectedTool
        if rotateScaleView.isHidden || rotateScaleView.alpha == 0 {
            return
        }
        
        // ✅ 退出裁剪模式：显示顶部按钮，隐藏底部按钮
        backButton.isHidden = false
        shareButton.isHidden = false
        saveButton.isHidden = false
        cancelButton.isHidden = true
        finishButton.isHidden = true
        
        toolsView.isHidden = false
        hideScaleSwitchView()
        UIView.animate(withDuration: 0.2) {
            if !self.config.cropSize.aspectRatios.isEmpty {
                self.ratioToolView.alpha = 0
            }
            self.rotateScaleView.alpha = 0
            self.resetButton.alpha = 0
            self.leftRotateButton.alpha = 0
            self.rightRotateButton.alpha = 0
            self.mirrorVerticallyButton.alpha = 0
            self.mirrorHorizontallyButton.alpha = 0
            self.maskListButton.alpha = 0
            // ✅ 退出裁剪模式：隐藏底部按钮
            self.cancelButton.alpha = 0
            self.finishButton.alpha = 0
            self.toolsView.alpha = 1
            self.showMasks()
        } completion: {
            if $0 {
                if !self.config.cropSize.aspectRatios.isEmpty {
                    self.ratioToolView.isHidden = true
                }
                self.rotateScaleView.isHidden = true
                self.resetButton.isHidden = true
                self.leftRotateButton.isHidden = true
                self.rightRotateButton.isHidden = true
                self.mirrorVerticallyButton.isHidden = true
                self.mirrorHorizontallyButton.isHidden = true
                self.maskListButton.isHidden = true
            }
        }
    }
    
    func showScaleSwitchView(_ isRatioClick: Bool = false) {
        if config.cropSize.aspectRatios.isEmpty {
            return
        }
        if let ratio = ratioToolView.selectedRatio?.ratio, (ratio.width < 0 || ratio.height < 0) {
            scaleSwitchView.isHidden = false
        }else {
            return
        }
        UIView.animate(withDuration: 0.2) {
            if !self.config.cropSize.aspectRatios.isEmpty {
                self.scaleSwitchView.alpha = 1
            }
            if isRatioClick {
                self.maskListButton.alpha = 0
            }
        } completion: {
            if $0, isRatioClick {
                self.maskListButton.isHidden = true
            }
        }
    }
    
    func hideScaleSwitchView(_ isRatioClick: Bool = false) {
        if config.cropSize.aspectRatios.isEmpty {
            return
        }
        if isRatioClick {
            maskListButton.isHidden = false
        }
        UIView.animate(withDuration: 0.2) {
            self.scaleSwitchView.alpha = 0
            if isRatioClick {
                self.maskListButton.alpha = 1
            }
        } completion: {
            if $0 {
                self.scaleSwitchView.isHidden = true
            }
        }
    }
    
    func presentText(_ text: EditorStickerText? = nil) {
        let textVC = EditorStickerTextViewController(config: config.text, stickerText: text)
        textVC.delegate = self
        let nav = EditorStickerTextController(rootViewController: textVC)
        nav.modalPresentationStyle = config.text.modalPresentationStyle
        present(nav, animated: true, completion: nil)
    }

    func showMainImageView() {
        if !mainImageView.isHidden && mainImageView.alpha == 1 {
            return
        }
        mainImageView.isHidden = false
        UIView.animate(withDuration: 0.2) {
            self.mainImageView.alpha = 1
        }
    }

    func hideMainImageView() {
        if mainImageView.isHidden || mainImageView.alpha == 0 {
            return
        }
        UIView.animate(withDuration: 0.2) {
            self.mainImageView.alpha = 0
        } completion: {
            if $0 {
                self.mainImageView.isHidden = true
            }
        }
    }
}

extension EditorViewController: EditorMaskListDelete {
    public func editorMaskList(_ chartletList: EditorMaskListProtocol, didSelectedWith image: UIImage) {
        let imageAspectRatio = image.size
        editorView.isFixedRatio = true
        editorView.setMaskImage(image, animated: true)
        editorView.setAspectRatio(imageAspectRatio, animated: true)
        ratioToolView.deselected()
        for (index, aspectRatio) in ratioToolView.ratios.enumerated() {
            if aspectRatio.ratio.equalTo(.init(width: -1, height: -1)) || aspectRatio.ratio.equalTo(.zero) {
                continue
            }
            let scale1 = CGFloat(Int(aspectRatio.ratio.width / aspectRatio.ratio.height * 1000)) / 1000
            let scale2 = CGFloat(Int(imageAspectRatio.width / imageAspectRatio.height * 1000)) / 1000
            if scale1 == scale2 {
                ratioToolView.scrollToIndex(at: index, animated: true)
                break
            }
        }
        resetButton.isEnabled = isReset
    }
}

protocol EditorMainImageViewDelegate: AnyObject {
    func mainImageView(
        _ view: EditorMainImageView,
        didSelectColor color: UIColor
    )
}

protocol EditorMainImageColorPickerViewDelegate: AnyObject {
    func mainImageColorPickerView(
        _ colorView: EditorMainImageColorPickerView,
        changedColor color: UIColor
    )
}

// MARK: - EditorMainImageColorPickerView

class EditorMainImageColorPickerView: UIView {
    weak var delegate: EditorMainImageColorPickerViewDelegate?
    let config: EditorConfiguration.Brush
    let brushColors: [String]

    private var collectionView: UICollectionView!

    init(config: EditorConfiguration.Brush) {
        self.config = config
        self.brushColors = config.colors
        super.init(frame: .zero)
        initViews()
    }

    private func initViews() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.itemSize = CGSize(width: 50, height: 50)
        layout.sectionInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(SimpleColorCell.self, forCellWithReuseIdentifier: "SimpleColorCell")
        addSubview(collectionView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.frame = bounds
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension EditorMainImageColorPickerView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var count = brushColors.count
        if config.addCustomColor {
            count += 1
        }
        return count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "SimpleColorCell",
            for: indexPath
        ) as! SimpleColorCell
        let isCustomColor = config.addCustomColor && indexPath.item == brushColors.count
        if isCustomColor {
            cell.setAsCustomColor()
        } else {
            let hexColor = brushColors[indexPath.item]
            cell.setColor(hexColor.color)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let isCustomColor = config.addCustomColor && indexPath.item == brushColors.count
        if isCustomColor {
            if #available(iOS 14.0, *) {
                let pickerVC = UIColorPickerViewController()
                pickerVC.delegate = self
                if let window = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    window.windows.first?.rootViewController?.present(pickerVC, animated: true)
                }
            }
        } else {
            let hexColor = brushColors[indexPath.item]
            delegate?.mainImageColorPickerView(self, changedColor: hexColor.color)
        }
    }
}

@available(iOS 14.0, *)
extension EditorMainImageColorPickerView: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        let color = viewController.selectedColor
        delegate?.mainImageColorPickerView(self, changedColor: color)
        viewController.dismiss(animated: true)
    }
}

// MARK: - EditorMainImagePickerViewDelegate

protocol EditorMainImagePickerViewDelegate: AnyObject {
    func mainImagePickerView(
        _ pickerView: EditorMainImagePickerView,
        didSelectImage image: UIImage
    )
    func mainImagePickerViewDidTapPhotoButton(
        _ pickerView: EditorMainImagePickerView
    )
}

// MARK: - EditorMainImagePickerView

class EditorMainImagePickerView: UIView {
    weak var delegate: EditorMainImagePickerViewDelegate?

    private var collectionView: UICollectionView!
    private var photoButton: UIButton!

    // Default images (red, green, blue)
    private var defaultImages: [UIImage] = []

    init() {
        super.init(frame: .zero)
        initViews()
        generateDefaultImages()
    }

    private func generateDefaultImages() {
        // Red image
        if let redImage = UIImage.imageFromColor(UIColor.red, size: CGSize(width: 100, height: 100)) {
            defaultImages.append(redImage)
        }

        // Green image
        if let greenImage = UIImage.imageFromColor(UIColor.green, size: CGSize(width: 100, height: 100)) {
            defaultImages.append(greenImage)
        }

        // Blue image
        if let blueImage = UIImage.imageFromColor(UIColor.blue, size: CGSize(width: 100, height: 100)) {
            defaultImages.append(blueImage)
        }
    }

    private func initViews() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 10
        layout.itemSize = CGSize(width: 80, height: 80)
        layout.sectionInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(MainImagePickerCell.self, forCellWithReuseIdentifier: "MainImagePickerCell")
        addSubview(collectionView)

        photoButton = UIButton(type: .custom)
        photoButton.setTitle("选择图片", for: .normal)
        photoButton.setTitleColor(.white, for: .normal)
        photoButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        photoButton.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        photoButton.layer.cornerRadius = 8
        photoButton.addTarget(self, action: #selector(didPhotoButtonTapped), for: .touchUpInside)
        addSubview(photoButton)
    }

    @objc private func didPhotoButtonTapped() {
        delegate?.mainImagePickerViewDidTapPhotoButton(self)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let photoButtonWidth: CGFloat = 100
        let photoButtonHeight: CGFloat = 50
        photoButton.frame = CGRect(
            x: width - photoButtonWidth - 12,
            y: (height - photoButtonHeight) / 2,
            width: photoButtonWidth,
            height: photoButtonHeight
        )

        let collectionViewWidth = width - photoButtonWidth - 24
        collectionView.frame = CGRect(
            x: 0,
            y: 0,
            width: collectionViewWidth,
            height: height
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension EditorMainImagePickerView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return defaultImages.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "MainImagePickerCell",
            for: indexPath
        ) as! MainImagePickerCell
        cell.setImage(defaultImages[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.mainImagePickerView(self, didSelectImage: defaultImages[indexPath.item])
    }
}

// MARK: - MainImagePickerCell

class MainImagePickerCell: UICollectionViewCell {
    private var imageView: UIView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView = UIView()
        imageView.layer.cornerRadius = 8
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.white.cgColor
        contentView.addSubview(imageView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setImage(_ image: UIImage) {
        imageView.backgroundColor = image.averageColor ?? .gray
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
    }

    override var isSelected: Bool {
        didSet {
            UIView.animate(withDuration: 0.2) {
                self.imageView.transform = self.isSelected ? CGAffineTransform(scaleX: 1.15, y: 1.15) : .identity
                self.imageView.layer.borderColor = self.isSelected ? UIColor.white.cgColor : UIColor.white.withAlphaComponent(0.5).cgColor
            }
        }
    }
}

// MARK: - SimpleColorCell

class SimpleColorCell: UICollectionViewCell {
    private var colorView: UIView!
    private var icon: UIImageView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        colorView = UIView()
        colorView.layer.cornerRadius = 22
        colorView.layer.masksToBounds = true
        contentView.addSubview(colorView)

        icon = UIImageView()
        icon.tintColor = .white
        contentView.addSubview(icon)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setColor(_ color: UIColor) {
        colorView.backgroundColor = color
        icon.image = nil
    }

    func setAsCustomColor() {
        colorView.backgroundColor = .clear
        colorView.layer.borderWidth = 2
        colorView.layer.borderColor = UIColor.white.cgColor
        if #available(iOS 13.0, *) {
            icon.image = UIImage(systemName: "plus", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold))
        } else {
            // Fallback on earlier versions
        }
        icon.tintColor = .white
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        colorView.frame = CGRect(x: (width - 44) / 2, y: (height - 44) / 2, width: 44, height: 44)
        icon.frame = colorView.bounds
    }

    override var isSelected: Bool {
        didSet {
            UIView.animate(withDuration: 0.2) {
                self.colorView.transform = self.isSelected ? CGAffineTransform(scaleX: 1.2, y: 1.2) : .identity
            }
        }
    }
}

// MARK: - EditorMainImageView

class EditorMainImageView: UIView {
    weak var delegate: EditorMainImageViewDelegate?
    let config: EditorConfiguration.Brush

    private var segmentedControl: UISegmentedControl!
    private var colorPickerView: EditorMainImageColorPickerView!
    private var imagePickerView: EditorMainImagePickerView!
    private var titleLabel: UILabel!

    init(config: EditorConfiguration.Brush) {
        self.config = config
        super.init(frame: .zero)
        initViews()
    }

    private func initViews() {
        backgroundColor = UIColor(white: 0, alpha: 0.5)

        // Segmented Control
        segmentedControl = UISegmentedControl(items: ["颜色", "图片"])
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.tintColor = .white
        segmentedControl.addTarget(self, action: #selector(didSegmentedControlChanged(_:)), for: .valueChanged)
        addSubview(segmentedControl)

        // Title Label
        titleLabel = UILabel()
        titleLabel.text = "选择颜色"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textAlignment = .center
        addSubview(titleLabel)

        // Color Picker View
        colorPickerView = EditorMainImageColorPickerView(config: config)
        colorPickerView.delegate = self
        addSubview(colorPickerView)

        // Image Picker View
        imagePickerView = EditorMainImagePickerView()
        imagePickerView.delegate = self
        imagePickerView.isHidden = true
        addSubview(imagePickerView)
    }

    @objc private func didSegmentedControlChanged(_ control: UISegmentedControl) {
        let isColorMode = control.selectedSegmentIndex == 0

        UIView.animate(withDuration: 0.2) {
            self.titleLabel.text = isColorMode ? "选择颜色" : "选择图片"
            self.colorPickerView.alpha = isColorMode ? 1 : 0
            self.imagePickerView.alpha = isColorMode ? 0 : 1
        } completion: { _ in
            self.colorPickerView.isHidden = !isColorMode
            self.imagePickerView.isHidden = isColorMode
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let segmentHeight: CGFloat = 35
        let topPadding: CGFloat = 10
        segmentedControl.frame = CGRect(
            x: 16,
            y: topPadding,
            width: width - 32,
            height: segmentHeight
        )

        let titleHeight: CGFloat = 30
        titleLabel.frame = CGRect(
            x: 0,
            y: segmentedControl.frame.maxY + 5,
            width: width,
            height: titleHeight
        )

        let contentHeight: CGFloat = 70
        colorPickerView.frame = CGRect(
            x: 0,
            y: titleLabel.frame.maxY,
            width: width,
            height: contentHeight
        )

        imagePickerView.frame = CGRect(
            x: 0,
            y: titleLabel.frame.maxY,
            width: width,
            height: contentHeight
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension EditorMainImageView: EditorMainImageColorPickerViewDelegate {
    func mainImageColorPickerView(
        _ colorView: EditorMainImageColorPickerView,
        changedColor color: UIColor
    ) {
        delegate?.mainImageView(self, didSelectColor: color)
    }
}

extension EditorMainImageView: EditorMainImagePickerViewDelegate {
    func mainImagePickerView(
        _ pickerView: EditorMainImagePickerView,
        didSelectImage image: UIImage
    ) {
        delegate?.mainImageView(self, didSelectColor: UIColor(patternImage: image))
    }

    func mainImagePickerViewDidTapPhotoButton(
        _ pickerView: EditorMainImagePickerView
    ) {
        // This will be handled by the EditorViewController
        if let window = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if let viewController = window.windows.first?.rootViewController {
                let imagePicker = UIImagePickerController()
                imagePicker.sourceType = .photoLibrary
                imagePicker.delegate = self
                viewController.present(imagePicker, animated: true)
            }
        }
    }
}

extension EditorMainImageView: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        defer {
            picker.dismiss(animated: true)
        }

        if let selectedImage = info[.originalImage] as? UIImage {
            delegate?.mainImageView(self, didSelectColor: UIColor(patternImage: selectedImage))
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - EditorViewController Extension

extension EditorViewController: EditorMainImageViewDelegate {
    func mainImageView(
        _ view: EditorMainImageView,
        didSelectColor color: UIColor
    ) {
        applyMainImageColor(color)
    }
}

extension EditorViewController {
    func applyMainImageColor(_ color: UIColor) {
        // 创建一个纯色图片，尺寸为当前编辑图片的尺寸
        if let currentImage = editorView.image {
            let size = currentImage.size
            let rect = CGRect(origin: .zero, size: size)

            // 开始图形上下文
            UIGraphicsBeginImageContextWithOptions(size, false, currentImage.scale)
            color.setFill()
            UIRectFill(rect)

            // 获取新生成的纯色图片
            let colorImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            // 更新编辑器中的图片
            if let colorImage = colorImage {
                editorView.updateImage(colorImage)
            }
        }
    }
}
