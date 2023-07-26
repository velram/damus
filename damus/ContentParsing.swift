//
//  ContentParsing.swift
//  damus
//
//  Created by William Casarin on 2023-07-22.
//

import Foundation

enum NoteContent {
    case note(NdbNote)
    case content(String)
}

func parse_note_content(content: NoteContent) -> Blocks {
    var out: [Block] = []
    
    var bs = note_blocks()
    bs.num_blocks = 0;
    
    blocks_init(&bs)

    var ts: TagsSequence? = nil

    let parsed_blocks_finish = {
        var i = 0
        while (i < bs.num_blocks) {
            let block = bs.blocks[i]

            if let converted = convert_block(block, tags: ts) {
                out.append(converted)
            }

            i += 1
        }

        let words = Int(bs.words)
        blocks_free(&bs)

        return Blocks(words: words, blocks: out)
    }

    switch content {
    case .content(let c):
        return c.withCString { cptr in
            damus_parse_content(&bs, cptr)
            return parsed_blocks_finish()
        }
    case .note(let note):
        ts = note.tags
        damus_parse_content(&bs, note.content_raw)
        return parsed_blocks_finish()
    }
}

func interpret_event_refs_ndb(blocks: [Block], tags: TagsSequence) -> [EventRef] {
    if tags.count == 0 {
        return []
    }
    
    /// build a set of indices for each event mention
    let mention_indices = build_mention_indices(blocks, type: .event)
    
    /// simpler case with no mentions
    if mention_indices.count == 0 {
        let ev_refs = References.ids(tags: tags)
        return interp_event_refs_without_mentions_ndb(ev_refs)
    }
    
    return interp_event_refs_with_mentions_ndb(tags: tags, mention_indices: mention_indices)
}

func interp_event_refs_without_mentions_ndb(_ ev_tags: LazyFilterSequence<References>) -> [EventRef] {

    var count = 0
    var evrefs: [EventRef] = []
    var first: Bool = true
    var first_ref: Reference? = nil

    for ref in ev_tags {
        if first {
            first_ref = ref
            evrefs.append(.thread_id(ref.to_referenced_id()))
            first = false
        } else {

            evrefs.append(.reply(ref.to_referenced_id()))
        }
        count += 1
    }

    if let first_ref, count == 1 {
        let r = first_ref.to_referenced_id()
        return [.reply_to_root(r)]
    }

    return evrefs
}

func interp_event_refs_with_mentions_ndb(tags: TagsSequence, mention_indices: Set<Int>) -> [EventRef] {
    var mentions: [EventRef] = []
    var ev_refs: [ReferencedId] = []
    var i: Int = 0
    
    for tag in tags {
        if tag.count >= 2,
           tag[0].matches_char("e"),
           let ref = tag_to_refid(tag)
        {
            if mention_indices.contains(i) {
                let mention = Mention(index: i, type: .event, ref: ref)
                mentions.append(.mention(mention))
            } else {
                ev_refs.append(ref)
            }
        }
        i += 1
    }
    
    var replies = interp_event_refs_without_mentions(ev_refs)
    replies.append(contentsOf: mentions)
    return replies
}
