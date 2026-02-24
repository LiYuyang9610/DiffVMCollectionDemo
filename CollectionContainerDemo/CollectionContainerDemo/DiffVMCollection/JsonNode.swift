//
//  JsonNode.swift
//  LegacyPlayground
//
//  Created by ByteDance on 2/9/26.
//

import Foundation

/// A recursive enumeration representing a generic JSON structure.
/// It can be used to decode and encode arbitrary JSON data where the exact schema is not known at compile time.
enum JSONNode: Codable {
    /// A JSON string value.
    case string(String)
    /// A JSON number value, stored precisely as a `Decimal`.
    case number(Decimal)
    /// A JSON boolean value.
    case bool(Bool)
    /// A JSON object (dictionary), represented as an array of key-value tuples to preserve key ordering.
    case object([(String, JSONNode)])
    /// A JSON array of nested `JSONNode` values.
    case array([JSONNode])
    /// A JSON null value.
    case null

    /// Decodes a `JSONNode` from the given decoder.
    /// It attempts to decode the payload by testing various matchers (String, Number, Bool, Object, Array, Null)
    /// until one succeeds.
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: `DecodingError.typeMismatch` if the data does not match any valid JSON type.
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

    /// Encodes the `JSONNode` into the given encoder.
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: An error if the encoding process fails.
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

// MARK: - Convenience Accessors

extension JSONNode {
    
    /// A boolean indicating whether the node represents a JSON `null`.
    var isNull: Bool {
        guard case .null = self else { return false }
        return true
    }
    
    /// The boolean value if the node is a `.bool`, otherwise `nil`.
    var bool: Bool? {
        guard case .bool(let value) = self else { return nil }
        return value
    }
    
    /// The boolean value if the node is a `.bool`, otherwise `false`.
    var boolValue: Bool {
        guard case .bool(let value) = self else { return false }
        return value
    }
    
    /// The string value if the node is a `.string`, otherwise an empty string `""`.
    var stringValue: String {
        guard case .string(let value) = self else { return "" }
        return value
    }

    /// The string value if the node is a `.string`, otherwise `nil`.
    var string: String? {
        guard case .string(let value) = self else { return nil }
        return value
    }

    /// The double value if the node is a `.number`, otherwise `0.0`.
    var doubleValue: Double {
        guard case .number(let value) = self else { return .zero }
        return (value as NSDecimalNumber).doubleValue
    }

    /// The double value if the node is a `.number`, otherwise `nil`.
    var double: Double? {
        guard case .number(let value) = self else { return nil }
        return (value as NSDecimalNumber).doubleValue
    }

    /// The integer value if the node is a `.number`, otherwise `0`.
    var intValue: Int {
        guard case .number(let value) = self else { return .zero }
        return (value as NSDecimalNumber).intValue
    }

    /// The integer value if the node is a `.number`, otherwise `nil`.
    var int: Int? {
        guard case .number(let value) = self else { return nil }
        return (value as NSDecimalNumber).intValue
    }

    /// The dictionary representation if the node is an `.object`, otherwise an empty dictionary.
    /// Note: If there are duplicate keys, the last encountered value is kept.
    var dictionaryValue: [String: JSONNode] {
        guard case .object(let value) = self else { return [:] }
        return Dictionary(value, uniquingKeysWith: { $1 }) // TODO: compare
    }

    /// The dictionary representation if the node is an `.object`, otherwise `nil`.
    /// Note: If there are duplicate keys, the last encountered value is kept.
    var dictionary: [String: JSONNode]? {
        guard case .object(let value) = self else { return nil }
        return Dictionary(value, uniquingKeysWith: { $1 }) // TODO: compare
    }

    /// The array representation if the node is an `.array`, otherwise an empty array.
    var arrayValue: [JSONNode] {
        guard case .array(let value) = self else { return [] }
        return value
    }

    /// The array representation if the node is an `.array`, otherwise `nil`.
    var array: [JSONNode]? {
        guard case .array(let value) = self else { return nil }
        return value
    }

    /// Accesses the value associated with the given key if the node is a JSON object.
    /// - Parameter key: The key to look up in the object.
    /// - Returns: The matched `JSONNode` value, or `.null` if the key is not found or the node is not an object.
    subscript(_ key: String) -> JSONNode {
        guard case .object(let value) = self else { return .null }
        return value.first { nodeKey, _ in
            key == nodeKey
        }?.1 ?? .null
    }
}

// MARK: - Decoding Matchers

private extension JSONNode {
    
    /// A protocol for components that attempt to decode specific JSON types.
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

    /// A dynamic coding key used to encode and decode JSON object dictionaries.
    struct StringKey: CodingKey {
        var intValue: Int? { nil }
        let stringValue: String
        init?(intValue: Int) { nil }
        init(stringValue: String) {
            self.stringValue = stringValue
        }
    }
}
