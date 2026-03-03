//
//  DummyPlayer.swift
//  CollectionContainerDemo
//
//  Created by ByteDance on 3/3/26.
//

import Foundation
import Combine

class DummyPlayer {
    let currentProgressState: CurrentValueSubject<Int, Never> = .init(.zero)
    
    var currentProgress: AnyPublisher<Int, Never> {
        currentProgressState.eraseToAnyPublisher()
    }
    
    let completionEvent: PassthroughSubject<Void, Never> = .init()
    
    let totalProgress: Int
    
    private var timerCancellable: AnyCancellable?
    
    init(totalProgress: Int) {
        self.totalProgress = totalProgress
    }
    
    func play() {
        guard timerCancellable == nil else { return }
        
        if currentProgressState.value >= totalProgress {
            currentProgressState.send(.zero)
        }
        
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect().sink(receiveValue: { [weak self] _ in
            guard let self else { return }
            if currentProgressState.value >= totalProgress {
                pause()
                completionEvent.send(())
            } else {
                currentProgressState.send(currentProgressState.value + 1)
            }
        })
    }
    
    func pause() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
}
