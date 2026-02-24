//
//  DiffVMSectionHandler.swift
//  LegacyPlayground
//
//  Created by ByteDance on 2/12/26.
//

import Foundation

/// 内部通信协议, section层级
protocol DiffVMSectionHandler: AnyObject {
    func itemIndex(for itemViewModel: any ViewModelNode) -> Int?
}
