//
//  AutoPlayService.swift
//  LegacyPlayground
//
//  Created by ByteDance on 2/12/26.
//

import Foundation
import Combine

protocol AutoPlayService: AnyObject {
    var visibleItemsGetter: (() -> [AutoPlayVisibleItemInfo])? { get set }
    var containerSizeGetter: (() -> CGSizeWrapper)? { get set }
    var playingItemShouldChange: AnyPublisher<AutoPlayItemsInfo, Never> { get }
    var playingInfo: AutoPlayItemsInfo { get }
    func contentScrolling(to contentOffset: CGSizeWrapper)
    func manuallyPlayItem(at indexPath: IndexPathWrapper?)
}

class AutoPlayServiceImpl: AutoPlayService {
    
    private var recordedContentOffset: CGSizeWrapper = CGSizeWrapper(width: .zero, height: .zero)
    
    private var playRules: [AutoPlayRule] = []
    
    var visibleItemsGetter: (() -> [AutoPlayVisibleItemInfo])?
    
    var containerSizeGetter: (() -> CGSizeWrapper)?
    
    private let currentPlayingVideoState: CurrentValueSubject<AutoPlayItemsInfo, Never> = .init(AutoPlayItemsInfo(previousInfo: nil, currentInfo: nil))
    
    var playingInfo: AutoPlayItemsInfo {
        currentPlayingVideoState.value
    }
    
    init(playRules: [AutoPlayRule]) {
        self.playRules = playRules
    }
    
    var playingItemShouldChange: AnyPublisher<AutoPlayItemsInfo, Never> {
        currentPlayingVideoState.eraseToAnyPublisher()
    }
    
    func contentScrolling(to contentOffset: CGSizeWrapper) {
        defer { recordedContentOffset = contentOffset }
        var scrollDirection: ScrollGestureDirection = .none
        if abs(contentOffset.height - recordedContentOffset.height) >= .ulpOfOne {
            scrollDirection.insert(contentOffset.height > recordedContentOffset.height ? .up : .down)
        }
        if abs(contentOffset.width - recordedContentOffset.width) >= .ulpOfOne {
            scrollDirection.insert(contentOffset.width > recordedContentOffset.width ? .left : .right)
        }
        let visibleItems = visibleItemsGetter?() ?? []
        let containerSize = containerSizeGetter?() ?? .zero
        let situation = AutoPlayContainerSituation(contentOffset: contentOffset, scrollDirection: scrollDirection, visibleItems: visibleItems, containerSize: containerSize)
        applyRules(for: playRules, basedOn: situation) { itemsInfo in
            guard itemsInfo != currentPlayingVideoState.value else { return }
            guard itemsInfo.currentInfo != itemsInfo.previousInfo else { return } // 防止多次调用同一个视频的pause/play
            currentPlayingVideoState.send(itemsInfo)
        }
    }
    
    func manuallyPlayItem(at indexPath: IndexPathWrapper?) {
        if let indexPath {
            currentPlayingVideoState.send(AutoPlayItemsInfo(previousInfo: currentPlayingVideoState.value.currentInfo, currentInfo: AutoPlayItemInfo(indexPath: indexPath)))
        } else {
            currentPlayingVideoState.send(AutoPlayItemsInfo(previousInfo: currentPlayingVideoState.value.currentInfo, currentInfo: nil))
        }
    }
    
    private func applyRules(for leftRules: [AutoPlayRule], basedOn situation: AutoPlayContainerSituation, _ handler: (AutoPlayItemsInfo) -> Void) {
        guard let nextRule = leftRules.first else {
            handler(currentPlayingVideoState.value)
            return
        }
        guard nextRule.shouldApply(basedOn: situation) else {
            applyRules(for: Array(leftRules.dropFirst()), basedOn: situation, handler)
            return
        }
        switch nextRule.evaluate(basedOn: situation) {
        case .continueProcess:
            applyRules(for: Array(leftRules.dropFirst()), basedOn: situation, handler)
        case .finishProcess:
            handler(currentPlayingVideoState.value)
        case .startPlayItem(let itemToPlay):
            handler(AutoPlayItemsInfo(previousInfo: currentPlayingVideoState.value.currentInfo, currentInfo: itemToPlay))
        }
    }
}
