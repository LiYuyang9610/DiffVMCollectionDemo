//
//  DiffVMCellProtocol.swift
//  LegacyPlayground
//
//  Created by ByteDance on 2/12/26.
//

import Foundation
import UIKit

/// 接入方Cell需要实现协议
protocol DiffVMCellProtocol where Self: UICollectionViewCell {
    associatedtype ViewModelType: ViewModelNode & Hashable
    static var reuseIdentifier: String { get }
    func preferredSize(for viewModel: ViewModelType, within containerSize: CGSize) -> CGSize
    func bind(to viewModel: ViewModelType)
}
