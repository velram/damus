//
//  Id.swift
//  damus
//
//  Created by William Casarin on 2023-07-26.
//

import Foundation

struct QuoteId: IdType, TagKey {
    let id: Data
    
    init(_ data: Data) {
        self.id = data
    }

    var keychar: AsciiCharacter { "q" }
}


struct ReplaceableParam: TagConvertible {
    let param: TagElem

    static func from_tag(tag: TagSequence) -> ReplaceableParam? {
        var i = tag.makeIterator()

        guard tag.count >= 2,
              let t0 = i.next(),
              let chr = t0.single_char,
              chr == "d",
              let t1 = i.next() else {
            return nil
        }

        return ReplaceableParam(param: t1)
    }

    var tag: [String] { [self.keychar.description, self.param.string()] }
    var keychar: AsciiCharacter { "d" }
}

struct Signature: Hashable, Equatable {
    let data: Data

    init(_ p: Data) {
        self.data = p
    }
}
