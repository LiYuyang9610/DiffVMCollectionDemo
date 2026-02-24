//
//  ViewModelNode.swift
//  LegacyPlayground
//
//  Created by ByteDance on 2/6/26.
//

import Foundation

class ServicesContainer {

    struct ServiceKey: Hashable {
        let type: Any.Type

        static func == (lhs: ServiceKey, rhs: ServiceKey) -> Bool {
            lhs.type == rhs.type
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(ObjectIdentifier(type))
        }
    }

    struct ServiceValue {
        let service: Any
    }

    var services: [ServiceKey: ServiceValue] = [:]

    func registerService<ServiceType>(for protocolType: ServiceType.Type, using service: ServiceType) {
        services[ServiceKey(type: protocolType)] = ServiceValue(service: service)
    }

    func getService<ServiceType>(for protocolType: ServiceType.Type) -> ServiceType? {
        services[ServiceKey(type: protocolType)]?.service as? ServiceType
    }
}

protocol ViewModelNode: AnyObject {
    var servicesContainer: ServicesContainer { get }

    var parentViewModel: ViewModelNode? { get set }

    var childrenViewModels: [ViewModelNode] { get }
    
    func transform()
    
    func registerService<ServiceType>(for protocolType: ServiceType.Type, using service: ServiceType)

    func getService<ServiceType>(for protocolType: ServiceType.Type) -> ServiceType?
    
    func findParentValue<ValueType, ParentType>(for protocolType: ParentType.Type, _ action: (ParentType) -> ValueType?) -> ValueType?
    
    func findChildrenValue<ValueType, ChildType>(for protocolType: ChildType.Type, _ action: (ChildType) -> ValueType?) -> ValueType?
    
    func notifyParent<ParentType>(for protocolType: ParentType.Type, _ action: (ParentType) -> Void)

    func notifyParentsUntilRoot<ParentType>(for protocolType: ParentType.Type, _ action: (ParentType) -> Void)
    
    func notifyChildren<ChildType>(for protocolType: ChildType.Type, _ action: (ChildType) -> Void)

    func notifyDirectChildren<ChildType>(for protocolType: ChildType.Type, _ action: (ChildType) -> Void)
    
    func notifyChildrenUntilShoot<ChildType>(for protocolType: ChildType.Type, _ action: (ChildType) -> Void)
}

extension ViewModelNode {
    
    var childrenViewModels: [ViewModelNode] { [] }
    
    func registerService<ServiceType>(for protocolType: ServiceType.Type, using service: ServiceType) {
        servicesContainer.registerService(for: protocolType, using: service)
    }

    func getService<ServiceType>(for protocolType: ServiceType.Type) -> ServiceType? {
        if let targetService = servicesContainer.getService(for: protocolType) {
            return targetService
        }
        guard let parentViewModel else { return nil }
        return parentViewModel.getService(for: protocolType)
    }
    
    func findParentValue<ValueType, ParentType>(for protocolType: ParentType.Type, _ action: (ParentType) -> ValueType?) -> ValueType? {
        (parentViewModel as? ParentType).map { targetParentViewModel in
            action(targetParentViewModel)
        } ?? parentViewModel?.findParentValue(for: protocolType, action)
    }
    
    func findChildrenValue<ValueType, ChildType>(for protocolType: ChildType.Type, _ action: (ChildType) -> ValueType?) -> ValueType? {
        var queue = childrenViewModels
        while !queue.isEmpty {
            guard let currentChild = queue.first else { continue }
            queue = Array(queue.dropFirst(1))
            guard let targetChild = currentChild as? ChildType,
                  let result = action(targetChild) else {
                queue.append(contentsOf: currentChild.childrenViewModels)
                continue
            }
            return result
        }
        return nil
    }
    
    func findDirectChildrenValue<ValueType, ChildType>(for protocolType: ChildType.Type, _ action: (ChildType) -> ValueType?) -> ValueType? {
        for childViewModel in childrenViewModels {
            guard let candidateChildViewModel = childViewModel as? ChildType else { continue }
            guard let result = action(candidateChildViewModel) else { continue }
            return result
        }
        return nil
    }

    func notifyParent<ParentType>(for protocolType: ParentType.Type, _ action: (ParentType) -> Void) {
        guard let parentViewModel else { return }
        if let targetViewModel = parentViewModel as? ParentType {
            action(targetViewModel)
        } else {
            parentViewModel.notifyParent(for: protocolType, action)
        }
    }

    func notifyParentsUntilRoot<ParentType>(for protocolType: ParentType.Type, _ action: (ParentType) -> Void) {
        guard let parentViewModel else { return }
        if let targetViewModel = parentViewModel as? ParentType {
            action(targetViewModel)
        }
        parentViewModel.notifyParent(for: protocolType, action)
    }
    
    func notifyChildrenUntilShoot<ChildType>(for protocolType: ChildType.Type, _ action: (ChildType) -> Void) {
        var queue = childrenViewModels
        while !queue.isEmpty {
            let currentVM = queue.removeFirst()
            queue.append(contentsOf: currentVM.childrenViewModels)
            guard let matchedChild = currentVM as? ChildType else { continue }
            action(matchedChild)
        }
    }
    
    func notifyDirectChildren<ChildType>(for protocolType: ChildType.Type, _ action: (ChildType) -> Void) {
        childrenViewModels.compactMap { child in
            child as? ChildType
        }.forEach { matchedChild in
            action(matchedChild)
        }
    }
    
    func notifyChildren<ChildType>(for protocolType: ChildType.Type, _ action: (ChildType) -> Void) {
        var currentLevel = childrenViewModels
        while !currentLevel.isEmpty {
            let matchedInThisLevel: [ChildType] = currentLevel.compactMap { $0 as? ChildType }
            guard !matchedInThisLevel.isEmpty else {
                currentLevel = currentLevel.flatMap { $0.childrenViewModels }
                continue
            }
            matchedInThisLevel.forEach { action($0) }
            return
        }
    }
}
