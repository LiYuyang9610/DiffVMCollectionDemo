//
//  AutoPlayData.swift
//  LegacyPlayground
//
//  Created by ByteDance on 2/12/26.
//

import Foundation

struct ScrollGestureDirection: OptionSet {
    static let none = ScrollGestureDirection(rawValue: 1)
    static let up = ScrollGestureDirection(rawValue: 1 << 1)
    static let down = ScrollGestureDirection(rawValue: 1 << 2)
    static let left = ScrollGestureDirection(rawValue: 1 << 3)
    static let right = ScrollGestureDirection(rawValue: 1 << 4)
    
    let rawValue: Int
}

struct AutoPlayItemInfo: Equatable {
    let indexPath: IndexPathWrapper
}

struct AutoPlayVisibleItemInfo {
    let indexPath: IndexPathWrapper
    let frame: CGRectWrapper
}

struct AutoPlayItemsInfo: Equatable {
    static func == (lhs: AutoPlayItemsInfo, rhs: AutoPlayItemsInfo) -> Bool {
        lhs.previousInfo == rhs.previousInfo && lhs.currentInfo == rhs.currentInfo
    }
    
    let previousInfo: AutoPlayItemInfo?
    let currentInfo: AutoPlayItemInfo?
}

struct AutoPlayContainerSituation {
    let contentOffset: CGSizeWrapper
    let scrollDirection: ScrollGestureDirection
    let visibleItems: [AutoPlayVisibleItemInfo]
}

enum AutoPlayRuleAction {
    case continueProcess
    case finishProcess
    case startPlayItem(AutoPlayItemInfo)
}
