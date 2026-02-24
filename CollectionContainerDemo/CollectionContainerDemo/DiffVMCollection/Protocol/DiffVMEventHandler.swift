//
//  DiffVMEventHandler.swift
//  LegacyPlayground
//
//  Created by ByteDance on 2/12/26.
//

import Foundation

/// 接入方定义的 DiffVMCollectionViewModel 的父view model需要实现的协议用于接收CollectionView事件
protocol DiffVMEventHandler {
    func selectItem(at indexPath: IndexPath, with itemId: AnyHashable)
}

extension DiffVMEventHandler {
    func selectItem(at indexPath: IndexPath, with itemId: AnyHashable) {}
}
