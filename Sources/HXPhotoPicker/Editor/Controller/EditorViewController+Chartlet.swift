//
//  EditorViewController+Chartlet.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/5/17.
//

import UIKit

extension EditorViewController: EditorChartletListDelegate {
    public func chartletList(
        _ chartletList: EditorChartletListProtocol,
        didSelectedWith type: EditorChartletType
    ) {
        deselectedDrawTool()
        if let tool = selectedTool,
           tool.type == .graffiti || tool.type == .mosaic {
            selectedTool = nil
            updateBottomMaskLayer()
        }
        
        // Add the main sticker (image)
        let imageItemView: EditorStickersItemBaseView
        switch type {
        case .image(let image, _):
            imageItemView = editorView.addSticker(image)
        case .data(let data, _):
            imageItemView = editorView.addSticker(data)
        }
        
        // If chartlet has name or description, add text stickers below the image
        if let chartlet = type.chartlet {
            addTextStickersForChartlet(chartlet, below: imageItemView)
        }
        
        checkSelectedTool()
        checkFinishButtonState()
    }
    func deselectedDrawTool() {
        if let tool = lastSelectedTool {
            switch tool.type {
            case .graffiti, .mosaic:
                toolsView.deselected()
                editorView.isMosaicEnabled = false
                editorView.isDrawEnabled = false
                hideBrushColorView()
                hideMosaicToolView()
                lastSelectedTool = nil
            default:
                break
            }
        }
    }
    
    private func addTextStickersForChartlet(_ chartlet: EditorChartlet, below imageItemView: EditorStickersItemBaseView) {
        var previousItemView = imageItemView
        let spacing: CGFloat = 10 // Spacing between stickers
        
        // Add name text sticker if available
        if let name = chartlet.name, !name.isEmpty {
            let nameText = createStickerText(from: name)
            let nameItemView = editorView.addSticker(nameText, isSelected: false)
            positionTextSticker(nameItemView, below: previousItemView, spacing: spacing)
            previousItemView = nameItemView
        }
        
        // Add description text sticker if available
        if let description = chartlet.description, !description.isEmpty {
            let descriptionText = createStickerText(from: description)
            let descriptionItemView = editorView.addSticker(descriptionText, isSelected: false)
            positionTextSticker(descriptionItemView, below: previousItemView, spacing: spacing)
        }
    }
    
    private func createStickerText(from text: String) -> EditorStickerText {
        // Use default text configuration
        let textConfig = config.text
        let fontSize = textConfig.defaultFontSize
        let textColor = textConfig.colors.first?.color ?? .white
        
        // Create attributed string with the text
        let font = UIFont.systemFont(ofSize: fontSize)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        
        // Calculate text size
        let maxWidth: CGFloat = editorView.bounds.width - 40
        let textSize = attributedString.boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).size
        
        // Create image from text
        let imageSize = CGSize(
            width: ceil(textSize.width) + 20,
            height: ceil(textSize.height) + 20
        )
        
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        let textImage = renderer.image { context in
            let rect = CGRect(origin: .zero, size: imageSize)
            
            // Draw text
            attributedString.draw(
                in: CGRect(
                    x: 10,
                    y: 10,
                    width: textSize.width,
                    height: textSize.height
                )
            )
        }
        
        return EditorStickerText(
            image: textImage,
            text: text,
            textColor: textColor,
            showBackgroud: false,
            fontSize: fontSize
        )
    }
    
    private func positionTextSticker(_ textItemView: EditorStickersItemBaseView, below previousItemView: EditorStickersItemBaseView, spacing: CGFloat) {
        // Calculate position below the previous item
        // Note: The exact positioning depends on the coordinate system of the editor view
        // This positions the text sticker below the image sticker with some spacing
        DispatchQueue.main.async {
            let previousFrame = previousItemView.frame
            let newY = previousFrame.maxY + spacing
            let newX = previousFrame.midX - textItemView.frame.width / 2
            
            textItemView.center = CGPoint(
                x: newX + textItemView.frame.width / 2,
                y: newY + textItemView.frame.height / 2
            )
        }
    }
}

extension EditorViewController: EditorChartletViewControllerDelegate {
    
    func chartletViewController(
        _ chartletViewController: EditorChartletViewController,
        loadTitleChartlet response: @escaping ([EditorChartlet]) -> Void
    ) {
        if let editorDelegate = delegate {
            editorDelegate.editorViewController(
                self,
                loadTitleChartlet: response
            )
        }else {
            let titles = PhotoTools.defaultTitleChartlet()
            response(titles)
        }
    }
    func chartletViewController(
        _ chartletViewController: EditorChartletViewController,
        titleChartlet: EditorChartlet,
        titleIndex: Int,
        loadChartletList response: @escaping (Int, [EditorChartlet]) -> Void
    ) {
        if let editorDelegate = delegate {
            editorDelegate.editorViewController(
                self,
                titleChartlet: titleChartlet,
                titleIndex: titleIndex,
                loadChartletList: response
            )
        }else {
            // 默认加载这些贴图
            let chartletList = PhotoTools.defaultNetworkChartlet()
            response(titleIndex, chartletList)
        }
    }
}

// MARK: - Preset Stickers
extension EditorViewController {
    
    /// Add preset stickers configured in EditorConfiguration
    /// 添加配置中的预设贴纸
    func addPresetStickers() {
        guard !config.presetStickers.isEmpty else { return }
        
        for presetSticker in config.presetStickers {
            addPresetSticker(presetSticker)
        }
        
        // Deselect all stickers after adding
        editorView.deselectedSticker()
    }
    
    /// Add a single preset sticker
    /// 添加单个预设贴纸
    private func addPresetSticker(_ presetSticker: EditorConfiguration.PresetSticker) {
        let chartlet = presetSticker.chartlet
        
        // Add the main sticker (image)
        let imageItemView: EditorStickersItemBaseView
        if let image = chartlet.image {
            imageItemView = editorView.addSticker(image, isSelected: false)
        } else if let url = chartlet.url {
            // For URL-based stickers, we need to download first
            // For now, skip URL stickers in preset (can be enhanced later)
            return
        } else {
            return
        }
        
        // Position the main sticker
        positionPresetSticker(imageItemView, at: presetSticker.position, scale: presetSticker.scale)
        
        // Add name and description text stickers below the image (if available)
        addTextStickersForChartlet(chartlet, below: imageItemView)
    }
    
    /// Position a preset sticker
    /// 定位预设贴纸
    private func positionPresetSticker(
        _ itemView: EditorStickersItemBaseView,
        at position: EditorConfiguration.PresetText.Position,
        scale: CGFloat
    ) {
        let viewWidth = editorView.width
        let viewHeight = editorView.height
        let margin: CGFloat = 60  // Safety margin from edges
        
        let centerPoint: CGPoint
        
        switch position {
        case .topLeft:
            centerPoint = CGPoint(x: margin, y: margin)
        case .topCenter:
            centerPoint = CGPoint(x: viewWidth * 0.5, y: margin)
        case .topRight:
            centerPoint = CGPoint(x: viewWidth - margin, y: margin)
        case .centerLeft:
            centerPoint = CGPoint(x: margin, y: viewHeight * 0.5)
        case .center:
            centerPoint = CGPoint(x: viewWidth * 0.5, y: viewHeight * 0.5)
        case .centerRight:
            centerPoint = CGPoint(x: viewWidth - margin, y: viewHeight * 0.5)
        case .bottomLeft:
            centerPoint = CGPoint(x: margin, y: viewHeight - margin)
        case .bottomCenter:
            centerPoint = CGPoint(x: viewWidth * 0.5, y: viewHeight - margin)
        case .bottomRight:
            centerPoint = CGPoint(x: viewWidth - margin, y: viewHeight - margin)
        case .custom(let relativePoint):
            // Use relative coordinates (0.0-1.0)
            centerPoint = CGPoint(
                x: viewWidth * relativePoint.x,
                y: viewHeight * relativePoint.y
            )
        }
        
        itemView.center = centerPoint
        
        // Apply scale if needed
        if scale != 1.0 {
            // The itemView has a pinchScale property that can be used
            // We need to trigger the scaling through the view's transform or pinchScale
            if let stickerItemView = itemView as? EditorStickersItemView {
                // Apply scale through pinch gesture simulation or direct property
                // Note: The exact API might need adjustment based on the internal implementation
                stickerItemView.transform = CGAffineTransform(scaleX: scale, y: scale)
            }
        }
    }
}
