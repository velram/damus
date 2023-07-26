//
//  ReferencedId.swift
//  damus
//
//  Created by William Casarin on 2023-07-22.
//

import Foundation

func tagref_should_be_id(_ tag: NdbTagElem) -> Bool {
    return !(tag.matches_char("t") || tag.matches_char("d"))
}


struct References<T: TagConvertible>: Sequence, IteratorProtocol {
    let tags: TagsSequence
    var tags_iter: TagsIterator

    init(tags: TagsSequence) {
        self.tags = tags
        self.tags_iter = tags.makeIterator()
    }

    mutating func next() -> T? {
        while let tag = tags_iter.next() {
            guard let evref = T.from_tag(tag: tag) else { continue }
            return evref
        }
        return nil
    }
}

extension References {
    var first: T? {
        self.first(where: { _ in true })
    }

    var last: T? {
        var last: T? = nil
        for t in self {
            last = t
        }
        return last
    }
}


// NdbTagElem transition helpers
extension String {
    func string() -> String {
        return self
    }

    func first_char() -> AsciiCharacter? {
        self.first.flatMap { chr in AsciiCharacter(chr) }
    }

    func matches_char(_ c: AsciiCharacter) -> Bool {
        return self.first == c.character
    }
    
    func matches_str(_ str: String) -> Bool {
        return self == str
    }
}


