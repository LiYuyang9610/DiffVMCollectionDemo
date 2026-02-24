//
//  JsonNode.swift
//  LegacyPlayground
//
//  Created by ByteDance on 2/9/26.
//

import Foundation

enum JSONNode: Codable {
    case string(String)
    case number(Decimal)
    case bool(Bool)
    case object([(String, JSONNode)])
    case array([JSONNode])
    case null

    public init(from decoder: any Decoder) throws {
        let allMatchers: [JSONNodeMatchable] = [NilMatcher(), StringMatcher(), NumberMatcher(), BoolMatcher(), ObjectMatcher(), ArrayMatcher()]
        for matcher in allMatchers {
            guard let decodedValue = try? matcher.decode(from: decoder) else { continue }
            self = decodedValue
            return
        }
        throw DecodingError.typeMismatch(
            JSONNode.self,
            .init(codingPath: decoder.codingPath, debugDescription: "JSON structure error")
        )
    }

    func encode(to encoder: any Encoder) throws {
        switch self {
        case .string(let string):
            var container = encoder.singleValueContainer()
            try container.encode(string)
        case .number(let decimal):
            var container = encoder.singleValueContainer()
            try container.encode(decimal)
        case .bool(let bool):
            var container = encoder.singleValueContainer()
            try container.encode(bool)
        case .object(let array):
            var container = encoder.container(keyedBy: StringKey.self)
            try array.forEach { key, value in
                try container.encode(value, forKey: StringKey(stringValue: key))
            }
        case .array(let array):
            var container = encoder.unkeyedContainer()
            try array.forEach { JSONNode in
                try container.encode(JSONNode)
            }
        case .null:
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        }
    }
}

extension JSONNode {
    
    var isNull: Bool {
        guard case .null = self else { return false }
        return true
    }
    
    var bool: Bool? {
        guard case .bool(let value) = self else { return nil }
        return value
    }
    
    var boolValue: Bool {
        guard case .bool(let value) = self else { return false }
        return value
    }
    
    var stringValue: String {
        guard case .string(let value) = self else { return "" }
        return value
    }

    var string: String? {
        guard case .string(let value) = self else { return nil }
        return value
    }

    var doubleValue: Double {
        guard case .number(let value) = self else { return .zero }
        return (value as NSDecimalNumber).doubleValue
    }

    var double: Double? {
        guard case .number(let value) = self else { return nil }
        return (value as NSDecimalNumber).doubleValue
    }

    var intValue: Int {
        guard case .number(let value) = self else { return .zero }
        return (value as NSDecimalNumber).intValue
    }

    var int: Int? {
        guard case .number(let value) = self else { return nil }
        return (value as NSDecimalNumber).intValue
    }

    var dictionaryValue: [String: JSONNode] {
        guard case .object(let value) = self else { return [:] }
        return Dictionary(value, uniquingKeysWith: { $1 }) // TODO: compare
    }

    var dictionary: [String: JSONNode]? {
        guard case .object(let value) = self else { return nil }
        return Dictionary(value, uniquingKeysWith: { $1 }) // TODO: compare
    }

    var arrayValue: [JSONNode] {
        guard case .array(let value) = self else { return [] }
        return value
    }

    var array: [JSONNode]? {
        guard case .array(let value) = self else { return nil }
        return value
    }

    subscript(_ key: String) -> JSONNode {
        guard case .object(let value) = self else { return .null }
        return value.first { nodeKey, _ in
            key == nodeKey
        }?.1 ?? .null
    }
}

private extension JSONNode {
    protocol JSONNodeMatchable {
        func decode(from decoder: Decoder) throws -> JSONNode
    }

    struct NilMatcher: JSONNodeMatchable {
        func decode(from decoder: Decoder) throws -> JSONNode {
            if try decoder.singleValueContainer().decodeNil() {
                return .null
            } else {
                throw DecodingError.typeMismatch(JSONNode.self, .init(codingPath: decoder.codingPath, debugDescription: "no nil"))
            }
        }
    }

    struct StringMatcher: JSONNodeMatchable {
        func decode(from decoder: any Decoder) throws -> JSONNode {
            try .string(decoder.singleValueContainer().decode(String.self))
        }
    }

    struct NumberMatcher: JSONNodeMatchable {
        func decode(from decoder: any Decoder) throws -> JSONNode {
            try .number(decoder.singleValueContainer().decode(Decimal.self))
        }
    }

    struct BoolMatcher: JSONNodeMatchable {
        func decode(from decoder: any Decoder) throws -> JSONNode {
            try .bool(decoder.singleValueContainer().decode(Bool.self))
        }
    }

    struct ObjectMatcher: JSONNodeMatchable {
        func decode(from decoder: any Decoder) throws -> JSONNode {
            let keyedContainer = try decoder.container(keyedBy: StringKey.self)
            let pairs = try keyedContainer.allKeys.map(\.stringValue).map { key in
                try (key, keyedContainer.decode(JSONNode.self, forKey: StringKey(stringValue: key)))
            }
            return .object(pairs)
        }
    }

    struct ArrayMatcher: JSONNodeMatchable {
        func decode(from decoder: any Decoder) throws -> JSONNode {
            var array = try decoder.unkeyedContainer()
            var result: [JSONNode] = []
            if let count = array.count {
                result.reserveCapacity(count)
            }
            while !array.isAtEnd {
                try result.append(array.decode(JSONNode.self))
            }
            return .array(result)
        }
    }

    struct StringKey: CodingKey {
        var intValue: Int? { nil }
        let stringValue: String
        init?(intValue: Int) { nil }
        init(stringValue: String) {
            self.stringValue = stringValue
        }
    }
}
