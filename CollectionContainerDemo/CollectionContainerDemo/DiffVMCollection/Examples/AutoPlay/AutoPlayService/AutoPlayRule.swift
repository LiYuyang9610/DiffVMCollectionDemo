//
//  AutoPlayRule.swift
//  LegacyPlayground
//
//  Created by ByteDance on 2/12/26.
//

import Foundation

protocol AutoPlayRule {
    func shouldApply(basedOn situation: AutoPlayContainerSituation) -> Bool
    func evaluate(basedOn situation: AutoPlayContainerSituation) -> AutoPlayRuleAction
}

struct ForwardScrollRule: AutoPlayRule {
    let triggerLineLength: Double
    
    func shouldApply(basedOn situation: AutoPlayContainerSituation) -> Bool {
        situation.scrollDirection.contains(.up)
    }
    
    func evaluate(basedOn situation: AutoPlayContainerSituation) -> AutoPlayRuleAction {
        let offsetY = situation.contentOffset.height
        let sortedItems = situation.visibleItems.sorted { $0.indexPath > $1.indexPath }
        let allIndexPaths: Set<IndexPathWrapper> = Set(situation.visibleItems.map { $0.indexPath })
        for item in sortedItems where item.indexPath.item % 2 == 0 {
            let itemTopInBounds = item.frame.minY - offsetY
            if itemTopInBounds < triggerLineLength {
                let isBelowHalf = itemTopInBounds < (triggerLineLength - item.frame.height / 2)
                let targetIndex = isBelowHalf ? item.indexPath.item + 1 : item.indexPath.item
                let targetIndexPath = IndexPathWrapper(section: item.indexPath.section, item: targetIndex)
                if allIndexPaths.contains(targetIndexPath) {
                    return .startPlayItem(AutoPlayItemInfo(indexPath: targetIndexPath))
                } else {
                    return .startPlayItem(AutoPlayItemInfo(indexPath: item.indexPath))
                }
            }
        }
        return .continueProcess
    }
}

struct BackwardScrollRule: AutoPlayRule {
    let triggerLineLength: Double
    
    func shouldApply(basedOn situation: AutoPlayContainerSituation) -> Bool {
        situation.scrollDirection.contains(.down)
    }
    
    func evaluate(basedOn situation: AutoPlayContainerSituation) -> AutoPlayRuleAction {
        let offsetY = situation.contentOffset.height
        let sortedItems = situation.visibleItems.sorted { $0.indexPath < $1.indexPath }
        let allIndexPaths: Set<IndexPathWrapper> = Set(situation.visibleItems.map { $0.indexPath })
        for item in sortedItems where item.indexPath.item % 2 == 0 {
            let itemBottomInBounds = item.frame.maxY - offsetY
            if itemBottomInBounds > triggerLineLength {
                let isBelowHalf = itemBottomInBounds > (triggerLineLength + item.frame.height / 2)
                let targetIndex = isBelowHalf ? item.indexPath.item : item.indexPath.item + 1
                let targetIndexPath = IndexPathWrapper(section: item.indexPath.section, item: targetIndex)
                if allIndexPaths.contains(targetIndexPath) {
                    return .startPlayItem(AutoPlayItemInfo(indexPath: targetIndexPath))
                } else {
                    return .startPlayItem(AutoPlayItemInfo(indexPath: item.indexPath))
                }
            }
        }
        return .continueProcess
    }
}

struct LeftScrollRule: AutoPlayRule {
    let triggerLineLength: Double
    
    func shouldApply(basedOn situation: AutoPlayContainerSituation) -> Bool {
        situation.scrollDirection.contains(.left)
    }
    
    func evaluate(basedOn situation: AutoPlayContainerSituation) -> AutoPlayRuleAction {
        let offsetX = situation.contentOffset.width
        let sortedItems = situation.visibleItems.sorted { $0.indexPath > $1.indexPath }
        for item in sortedItems {
            if item.frame.minX <= triggerLineLength + offsetX {
                return .startPlayItem(AutoPlayItemInfo(indexPath: item.indexPath))
            }
        }
        return .continueProcess
    }
}

struct RightScrollRule: AutoPlayRule {
    let triggerLineLength: Double
    
    func shouldApply(basedOn situation: AutoPlayContainerSituation) -> Bool {
        situation.scrollDirection.contains(.right)
    }
    
    func evaluate(basedOn situation: AutoPlayContainerSituation) -> AutoPlayRuleAction {
        let offsetX = situation.contentOffset.width
        let sortedItems = situation.visibleItems.sorted { $0.indexPath > $1.indexPath }
        for item in sortedItems {
            if item.frame.minX <= triggerLineLength + offsetX {
                return .startPlayItem(AutoPlayItemInfo(indexPath: item.indexPath))
            }
        }
        return .continueProcess
    }
}

struct EndRule: AutoPlayRule {
    func shouldApply(basedOn situation: AutoPlayContainerSituation) -> Bool {
        true
    }
    
    func evaluate(basedOn situation: AutoPlayContainerSituation) -> AutoPlayRuleAction {
        .finishProcess
    }
}
