//
//  ViewModelNode.swift
//  LegacyPlayground
//
//  Created by ByteDance on 2/6/26.
//

import Foundation

/// A localized dependency injection container that stores and resolves services based on their protocol or concrete types.
class ServicesContainer {

    /// A structure used to uniquely identify a registered service type.
    struct ServiceKey: Hashable {
        let type: Any.Type

        static func == (lhs: ServiceKey, rhs: ServiceKey) -> Bool {
            lhs.type == rhs.type
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(ObjectIdentifier(type))
        }
    }

    /// A wrapper structure to hold the actual service instance.
    struct ServiceValue {
        let service: Any
    }

    /// The dictionary storing registered services, keyed by their type.
    var services: [ServiceKey: ServiceValue] = [:]

    /// Registers a service instance to a specific type.
    /// - Parameters:
    ///   - protocolType: The type (usually a protocol) to associate the service with.
    ///   - service: The concrete instance of the service.
    func registerService<ServiceType>(for protocolType: ServiceType.Type, using service: ServiceType) {
        services[ServiceKey(type: protocolType)] = ServiceValue(service: service)
    }

    /// Resolves and returns a service instance for a given type, if one has been registered.
    /// - Parameter protocolType: The type of the service to resolve.
    /// - Returns: The registered service instance, or `nil` if it's not found.
    func getService<ServiceType>(for protocolType: ServiceType.Type) -> ServiceType? {
        services[ServiceKey(type: protocolType)]?.service as? ServiceType
    }
}

/// A protocol representing a node within a hierarchical, tree-based ViewModel architecture.
/// This allows breaking down complex screen ViewModels into modular components that can share
/// dependencies and communicate bidirectionally using their types.
protocol ViewModelNode: AnyObject {
    
    /// The container managing dependencies injected specifically for this node.
    var servicesContainer: ServicesContainer { get }

    /// A reference to the parent node in the view model tree, if one exists.
    var parentViewModel: ViewModelNode? { get set }

    /// The collection of immediate child nodes descending from this view model.
    var childrenViewModels: [ViewModelNode] { get }
    
    /// Performs any necessary setup or state transformation for this node.
    func transform()
    
    /// Registers a service into this node's `ServicesContainer`.
    /// - Parameters:
    ///   - protocolType: The protocol or type serving as the key.
    ///   - service: The implementation instance to store.
    func registerService<ServiceType>(for protocolType: ServiceType.Type, using service: ServiceType)

    /// Retrieves a service. If the node doesn't have it locally, the request is propagated up to the parent.
    /// - Parameter protocolType: The protocol or type to resolve.
    /// - Returns: The resolved service instance, or `nil` if not found in the ancestor chain.
    func getService<ServiceType>(for protocolType: ServiceType.Type) -> ServiceType?
    
    /// Climbs up the parent tree looking for the first ancestor that matches the given type
    /// and can fulfill the requested value through the provided closure.
    /// - Parameters:
    ///   - protocolType: The expected type of the parent node.
    ///   - action: A closure executed on matching parents that returns a value if successful.
    /// - Returns: The matched value, or `nil` if no capable parent is found.
    func findParentValue<ValueType, ParentType>(for protocolType: ParentType.Type, _ action: (ParentType) -> ValueType?) -> ValueType?
    
    /// Searches downwards through the child tree (using Breadth-First Search) to find the first
    /// child matching the type that can fulfill the request through the closure.
    /// - Parameters:
    ///   - protocolType: The expected type of the child node.
    ///   - action: A closure executed on matching children that returns a value if successful.
    /// - Returns: The matched value, or `nil` if no capable child is found.
    func findChildrenValue<ValueType, ChildType>(for protocolType: ChildType.Type, _ action: (ChildType) -> ValueType?) -> ValueType?
    
    /// Climbs up the parent tree and executes a closure on the *first* ancestor that matches the given type.
    /// - Parameters:
    ///   - protocolType: The expected type of the parent node.
    ///   - action: The action to perform on the matched parent.
    func notifyParent<ParentType>(for protocolType: ParentType.Type, _ action: (ParentType) -> Void)

    /// Climbs up the parent tree and executes a closure on *every* ancestor that matches the given type, all the way to the root.
    /// - Parameters:
    ///   - protocolType: The expected type of the parent node.
    ///   - action: The action to perform on matching parents.
    func notifyParentsUntilRoot<ParentType>(for protocolType: ParentType.Type, _ action: (ParentType) -> Void)
    
    /// Searches downwards through children (Breadth-First Search). Executes the closure on matching children.
    /// Stops searching deeper branches once matches are found at a specific depth level.
    /// - Parameters:
    ///   - protocolType: The expected type of the child node.
    ///   - action: The action to perform on matching children.
    func notifyChildren<ChildType>(for protocolType: ChildType.Type, _ action: (ChildType) -> Void)

    /// Executes the closure only on the immediate (direct) children that match the given type.
    /// - Parameters:
    ///   - protocolType: The expected type of the child node.
    ///   - action: The action to perform on matching children.
    func notifyDirectChildren<ChildType>(for protocolType: ChildType.Type, _ action: (ChildType) -> Void)
    
    /// Traverses the entire child tree downwards (Breadth-First Search) and executes the closure
    /// on *all* nested children that match the given type, all the way to the leaf nodes.
    /// - Parameters:
    ///   - protocolType: The expected type of the child node.
    ///   - action: The action to perform on matching children.
    func notifyChildrenUntilShoot<ChildType>(for protocolType: ChildType.Type, _ action: (ChildType) -> Void)
}

// MARK: - Default Implementations

extension ViewModelNode {
    
    /// By default, a node has no children.
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
    
    /// Checks only the immediate children to find the first one matching the type that
    /// can fulfill the request through the closure.
    /// - Parameters:
    ///   - protocolType: The expected type of the child node.
    ///   - action: A closure executed on matching children that returns a value if successful.
    /// - Returns: The matched value, or `nil` if no capable immediate child is found.
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
            var foundMatch = false
            currentLevel.forEach { child in
                guard let matchedChild = child as? ChildType else { return }
                foundMatch = true
                action(matchedChild)
            }
            guard !foundMatch else { return }
            currentLevel = currentLevel.flatMap { $0.childrenViewModels }
        }
    }
}
