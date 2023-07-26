//
//  Hashtag.swift
//  damus
//
//  Created by William Casarin on 2023-07-30.
//

import Foundation

struct Hashtag: TagConvertible {
    let hashtag: String

    static func from_tag(tag: TagSequence) -> Hashtag? {
        var i = tag.makeIterator()

        guard tag.count >= 2,
              let t0 = i.next(),
              let chr = t0.single_char,
              chr == "t",
              let t1 = i.next() else {
            return nil
        }

        return Hashtag(hashtag: t1.string())
    }

    var tag: [String] { ["t", self.hashtag] }
    var keychar: AsciiCharacter { "t" }
}

