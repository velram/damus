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
    let mention_indices = build_mention_indices(blocks, type: .e)

    /// simpler case with no mentions
    if mention_indices.count == 0 {
        return interp_event_refs_without_mentions_ndb(tags.note.referenced_noterefs)
    }
    
    return interp_event_refs_with_mentions_ndb(tags: tags, mention_indices: mention_indices)
}

func interp_event_refs_without_mentions_ndb(_ ev_tags: References<NoteRef>) -> [EventRef] {

    var count = 0
    var evrefs: [EventRef] = []
    var first: Bool = true
    var first_ref: NoteRef? = nil

    for ref in ev_tags {
        if first {
            first_ref = ref
            evrefs.append(.thread_id(ref))
            first = false
        } else {

            evrefs.append(.reply(ref))
        }
        count += 1
    }

    if let first_ref, count == 1 {
        let r = first_ref
        return [.reply_to_root(r)]
    }

    return evrefs
}

func interp_event_refs_with_mentions_ndb(tags: TagsSequence, mention_indices: Set<Int>) -> [EventRef] {
    var mentions: [EventRef] = []
    var ev_refs: [NoteRef] = []
    var i: Int = 0

    for tag in tags {
        if let note_id = NoteRef.from_tag(tag: tag) {
            if mention_indices.contains(i) {
                mentions.append(.mention(.noteref(note_id, index: i)))
            } else {
                ev_refs.append(note_id)
            }
        }
        i += 1
    }
    
    var replies = interp_event_refs_without_mentions(ev_refs)
    replies.append(contentsOf: mentions)
    return replies
}
