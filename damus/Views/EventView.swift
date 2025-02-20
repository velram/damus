//
//  EventView.swift
//  damus
//
//  Created by William Casarin on 2022-04-11.
//

import Foundation
import SwiftUI

enum EventViewKind {
    case small
    case normal
    case selected
    case title
    case subheadline
}

struct EventView: View {
    let event: NostrEvent
    let options: EventViewOptions
    let damus: DamusState
    let pubkey: Pubkey

    init(damus: DamusState, event: NostrEvent, pubkey: Pubkey? = nil, options: EventViewOptions = []) {
        self.event = event
        self.options = options
        self.damus = damus
        self.pubkey = pubkey ?? event.pubkey
    }

    var body: some View {
        VStack {
            if event.known_kind == .boost {
                if let inner_ev = event.get_inner_event(cache: damus.events) {
                    RepostedEvent(damus: damus, event: event, inner_ev: inner_ev, options: options)
                } else {
                    EmptyView()
                }
            } else if event.known_kind == .zap {
                if let zap = damus.zaps.zaps[event.id] {
                    ZapEvent(damus: damus, zap: zap, is_top_zap: options.contains(.top_zap))
                } else {
                    EmptyView()
                }
            } else if event.known_kind == .longform {
                LongformPreview(state: damus, ev: event, options: options)
            } else {
                TextEvent(damus: damus, event: event, pubkey: pubkey, options: options)
                    //.padding([.top], 6)
            }
        }
    }
}

// blame the porn bots for this code
func should_show_images(settings: UserSettingsStore, contacts: Contacts, ev: NostrEvent, our_pubkey: Pubkey, booster_pubkey: Pubkey? = nil) -> Bool {
    if settings.always_show_images {
        return true
    }
    
    if ev.pubkey == our_pubkey {
        return true
    }
    if contacts.is_in_friendosphere(ev.pubkey) {
        return true
    }
    if let boost_key = booster_pubkey, contacts.is_in_friendosphere(boost_key) {
        return true
    }
    return false
}

extension View {
    func pubkey_context_menu(bech32_pubkey: Pubkey) -> some View {
        return self.contextMenu {
            Button {
                    UIPasteboard.general.string = bech32_pubkey
            } label: {
                Label(NSLocalizedString("Copy Account ID", comment: "Context menu option for copying the ID of the account that created the note."), image: "copy2")
            }
        }
    }
}

func format_relative_time(_ created_at: UInt32) -> String
{
    return time_ago_since(Date(timeIntervalSince1970: Double(created_at)))
}

func format_date(_ created_at: UInt32) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(created_at))
    let dateFormatter = DateFormatter()
    dateFormatter.timeStyle = .short
    dateFormatter.dateStyle = .short
    return dateFormatter.string(from: date)
}

func make_actionbar_model(ev: NoteId, damus: DamusState) -> ActionBarModel {
    let model = ActionBarModel.empty()
    model.update(damus: damus, evid: ev)
    return model
}

func eventviewsize_to_font(_ size: EventViewKind) -> Font {
    switch size {
    case .small:
        return .body
    case .normal:
        return .body
    case .selected:
        return .custom("selected", size: 21.0)
    case .title:
        return .title
    case .subheadline:
        return .subheadline
    }
}

func eventviewsize_to_uifont(_ size: EventViewKind) -> UIFont {
    switch size {
    case .small:
        return .preferredFont(forTextStyle: .body)
    case .normal:
        return .preferredFont(forTextStyle: .body)
    case .selected:
        return .preferredFont(forTextStyle: .title2)
    case .subheadline:
        return .preferredFont(forTextStyle: .subheadline)
    case .title:
        return .preferredFont(forTextStyle: .title1)
    }
}


struct EventView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            /*
            EventView(damus: test_damus_state(), event: NostrEvent(content: "hello there https://jb55.com/s/Oct12-150217.png https://jb55.com/red-me.jb55 cool", pubkey: "pk"), show_friend_icon: true, size: .small)
            EventView(damus: test_damus_state(), event: NostrEvent(content: "hello there https://jb55.com/s/Oct12-150217.png https://jb55.com/red-me.jb55 cool", pubkey: "pk"), show_friend_icon: true, size: .normal)
            EventView(damus: test_damus_state(), event: NostrEvent(content: "hello there https://jb55.com/s/Oct12-150217.png https://jb55.com/red-me.jb55 cool", pubkey: "pk"), show_friend_icon: true, size: .big)
            
             */

            EventView( damus: test_damus_state(), event: test_note )

            EventView( damus: test_damus_state(), event: test_longform_event.event, options: [.wide] )
        }
        .padding()
    }
}

