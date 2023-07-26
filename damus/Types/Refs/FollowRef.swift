//
//  FollowRef.swift
//  damus
//
//  Created by William Casarin on 2023-07-30.
//

import Foundation

enum FollowRef: TagKeys, TagConvertible, Equatable, Hashable {

    // NOTE: When adding cases make sure to update key and from_tag
    case pubkey(Pubkey)
    case hashtag(String)

    var key: FollowKeys {
        switch self {
        case .hashtag: return .t
        case .pubkey:  return .p
        }
    }

    enum FollowKeys: AsciiCharacter, TagKey, CustomStringConvertible {
        case p, t

        var keychar: AsciiCharacter { self.rawValue }
        var description: String { self.rawValue.description }
    }

    static func from_tag(tag: TagSequence) -> FollowRef? {
        guard tag.count >= 2 else { return nil }

        var i = tag.makeIterator()

        guard let t0   = i.next(),
              let c    = t0.single_char,
              let fkey = FollowKeys(rawValue: c),
              let t1   = i.next()
        else {
            return nil
        }

        switch fkey {
        case .p: return t1.id().map({ .pubkey(Pubkey($0)) })
        case .t: return .hashtag(t1.string())
        }
    }

    var tag: [String] {
        [key.description, self.description]
    }

    var description: String {
        switch self {
        case .pubkey(let pubkey): return pubkey.description
        case .hashtag(let string): return string
        }
    }
}

