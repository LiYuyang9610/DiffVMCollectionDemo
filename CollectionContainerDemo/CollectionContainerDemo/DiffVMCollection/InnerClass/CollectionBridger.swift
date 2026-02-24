//
//  CollectionBridger.swift
//  LegacyPlayground
//
//  Created by ByteDance on 2/12/26.
//

import Foundation
import UIKit

/// 用于隔绝Obj-C, 使用 CollectionViewDelegate 协议进行回传调用
class CollectionBridger: NSObject, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    class FallbackCell: UICollectionViewCell {
        static let reuseIdentifier: String = "CollectionHandler.FallbackCell"
    }
    weak var delegate: CollectionViewDelegate?
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        delegate?.sections.count ?? .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        delegate?.sections[safe: section]?.items.count ?? .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let item = delegate?.sections[safe: indexPath.section]?.items[safe: indexPath.item] else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: FallbackCell.reuseIdentifier, for: indexPath)
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: item.cellReuseIdentifier, for: indexPath)
        item.configure(cell)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        delegate?.sizeForItem(at: indexPath) ?? .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = delegate?.sections[safe: indexPath.section]?.items[safe: indexPath.item] else { return }
        delegate?.selectItem(at: indexPath, with: item.id)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        delegate?.insetForSection(at: section) ?? .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        delegate?.minimumLineSpacingForSection(at: section) ?? .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        delegate?.minimumInteritemSpacingForSection(at: section) ?? .zero
    }
}
