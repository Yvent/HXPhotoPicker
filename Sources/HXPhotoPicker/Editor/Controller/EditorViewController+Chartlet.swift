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
