//
//  EditorChartletListProtocol.swift
//  HXPhotoPicker
//
//  Created by Silence on 2023/11/7.
//  Copyright © 2023 Silence. All rights reserved.
//

import UIKit

public enum EditorChartletType {
    case image(UIImage, chartlet: EditorChartlet? = nil)
    case data(Data, chartlet: EditorChartlet? = nil)
    
    var chartlet: EditorChartlet? {
        switch self {
        case .image(_, let chartlet):
            return chartlet
        case .data(_, let chartlet):
            return chartlet
        }
    }
}

public protocol EditorChartletListDelegate: AnyObject {
    func chartletList(
        _ chartletList: EditorChartletListProtocol,
        didSelectedWith type: EditorChartletType
    )
}

public protocol EditorChartletListProtocol: UIViewController {
    var delegate: EditorChartletListDelegate? { get set }
    init(config: EditorConfiguration, editorType: EditorContentViewType)
}

