//
//  RefId.swift
//  damus
//
//  Created by William Casarin on 2023-07-30.
//

import Foundation

enum RefId: TagConvertible, TagKeys, Equatable, Hashable {
    case event(NoteId)
    case pubkey(Pubkey)
    case quote(QuoteId)
    case hashtag(TagElem)
    case param(TagElem)

    var key: RefKey {
        switch self {
        case .event:   return .e
        case .pubkey:  return .p
        case .quote:   return .q
        case .hashtag: return .t
        case .param:   return .d
        }
    }

    enum RefKey: AsciiCharacter, TagKey, CustomStringConvertible {
        case e, p, t, d, q

        var keychar: AsciiCharacter {
            self.rawValue
        }

        var description: String {
            self.keychar.description
        }
    }

    var tag: [String] {
        [self.key.description, self.description]
    }

    var description: String {
        switch self {
        case .event(let noteId): return noteId.hex()
        case .pubkey(let pubkey): return pubkey.hex()
        case .quote(let quote): return quote.hex()
        case .hashtag(let string): return string.string()
        case .param(let string): return string.string()
        }
    }

    static func from_tag(tag: TagSequence) -> RefId? {
        var i = tag.makeIterator()

        guard tag.count >= 2,
              let t0 = i.next(),
              let key = t0.single_char,
              let rkey = RefKey(rawValue: key),
              let t1 = i.next()
        else { return nil }

        switch rkey {
        case .e: return t1.id().map({ .event(NoteId($0)) })
        case .p: return t1.id().map({ .pubkey(Pubkey($0)) })
        case .q: return t1.id().map({ .quote(QuoteId($0)) })
        case .t: return .hashtag(t1)
        case .d: return .param(t1)
        }
    }
}
