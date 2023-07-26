//
//  Reply.swift
//  damus
//
//  Created by William Casarin on 2022-05-08.
//

import Foundation

struct ReplyDesc {
    let pubkeys: [String]
    let others: Int
}

func make_reply_description(_ tags: Tags) -> ReplyDesc {
    var c = 0
    var ns: [String] = []
    var i = tags.count

    for tag in tags {
        if tag.count >= 2 && tag[0].matches_char("p") {
            c += 1
            if ns.count < 2 {
                ns.append(tag[1].string())
            }
        }
        i -= 1
    }

    return ReplyDesc(pubkeys: ns, others: c)
}
