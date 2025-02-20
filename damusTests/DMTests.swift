//
//  DMTests.swift
//  damusTests
//
//  Created by William Casarin on 2023-01-14.
//

import XCTest
@testable import damus

final class DMTests: XCTestCase {

    var alice: Keypair {
        let sec = "494c680d20f202807a116a6915815bd76a27d62802e7585806f6a2e034cb5cdb"
        let pk  = "22d925632551a3299022e98de7f9c1087f79a21209f3413ec24ec219b08bd1e4"
        return Keypair(pubkey: pk, privkey: sec)
    }
    
    var bob: Keypair {
        let sec = "aa8920b05b4bd5c79fce46868ed5ebc82bdb91b211850b14541bfbd13953cfef"
        let pk = "5a9a277dca94260688ecf7d63053de8c121b7f01f609d7f84a1eb9cff64e4606"
        return Keypair(pubkey: pk, privkey: sec)
    }
    
    var charlie: Keypair {
        let sec = "4c79130952c9c3b017dad62f37f285853a9c53f2a1184d94594f5b860f30b5a5"
        let pk = "51c0d263fbfc4bf850805dccf9a29125071e6fed9619bff3efa9a6b5bbcc54a7"
        return Keypair(pubkey: pk, privkey: sec)
    }
    
    var dave: Keypair {
        let sec = "630ffd518084334cbb9ecb20d9532ce0658b8123f4ba565c236d0cea9a4a2cfe"
        let pk = "b42e44b555013239a0d5dcdb09ebde0857cd8a5a57efbba5a2b6ac78833cb9f0"
        return Keypair(pubkey: pk, privkey: sec)
    }
    
    var fiatjaf: Keypair {
        let sec = "5426893eab32191ec17a83a583d5c8f85adaabcab0fa56af277ea0b61f575599"
        let pub = "e27258d7be6d84038967334bfd0954f05801b1bcd85b2afa4c03cfd16ae4b0ad"
        return Keypair(pubkey: pub, privkey: sec)
    }
    
    func testDMSortOrder() throws {
        let notif = NewEventsBits()
        let pubkey = "3efdaebb1d8923ebd99c9e7ace3b4194ab45512e2be79c1b7d68d9243e0d2681"
        let model = DirectMessagesModel(our_pubkey: pubkey)
        
        let now = UInt32(Date().timeIntervalSince1970)

        let alice_to_bob = create_dm("hi bob", to_pk: bob.pubkey, tags: [["p", bob.pubkey]], keypair: alice, created_at: now)!
        let debouncer = Debouncer(interval: 3.0)
        handle_incoming_dms(debouncer: debouncer, prev_events: notif, dms: model, our_pubkey: alice.pubkey, evs: [alice_to_bob])

        XCTAssertEqual(model.dms.count, 1)
        XCTAssertEqual(model.dms[0].pubkey, bob.pubkey)

        let bob_to_alice = create_dm("hi alice", to_pk: alice.pubkey, tags: [["p", alice.pubkey]], keypair: bob, created_at: now + 1)!
        handle_incoming_dms(debouncer: debouncer, prev_events: notif, dms: model, our_pubkey: alice.pubkey, evs: [bob_to_alice])

        XCTAssertEqual(model.dms.count, 1)
        XCTAssertEqual(model.dms[0].pubkey, bob.pubkey)
        
        let alice_to_bob_2 = create_dm("hi bob", to_pk: bob.pubkey, tags: [["p", bob.pubkey]], keypair: alice, created_at: now + 2)!
        handle_incoming_dms(debouncer: debouncer, prev_events: notif, dms: model, our_pubkey: alice.pubkey, evs: [alice_to_bob_2])

        XCTAssertEqual(model.dms.count, 1)
        XCTAssertEqual(model.dms[0].pubkey, bob.pubkey)
        
        let fiatjaf_to_alice = create_dm("hi alice", to_pk: alice.pubkey, tags: [["p", alice.pubkey]], keypair: fiatjaf, created_at: now+5)!
        handle_incoming_dms(debouncer: debouncer, prev_events: notif, dms: model, our_pubkey: alice.pubkey, evs: [fiatjaf_to_alice])

        XCTAssertEqual(model.dms.count, 2)
        XCTAssertEqual(model.dms[0].pubkey, fiatjaf.pubkey)
        
        let dave_to_alice = create_dm("hi alice", to_pk: alice.pubkey, tags: [["p", alice.pubkey]], keypair: dave, created_at: now + 10)!
        handle_incoming_dms(debouncer: debouncer, prev_events: notif, dms: model, our_pubkey: alice.pubkey, evs: [dave_to_alice])

        XCTAssertEqual(model.dms.count, 3)
        XCTAssertEqual(model.dms[0].pubkey, dave.pubkey)

        let bob_to_alice_2 = create_dm("hi alice 2", to_pk: alice.pubkey, tags: [["p", alice.pubkey]], keypair: bob, created_at: now + 15)!
        handle_incoming_dms(debouncer: debouncer, prev_events: notif, dms: model, our_pubkey: alice.pubkey, evs: [bob_to_alice_2])

        XCTAssertEqual(model.dms.count, 3)
        XCTAssertEqual(model.dms[0].pubkey, bob.pubkey)

        let charlie_to_alice = create_dm("hi alice", to_pk: alice.pubkey, tags: [["p", alice.pubkey]], keypair: charlie, created_at: now + 20)!
        handle_incoming_dms(debouncer: debouncer, prev_events: notif, dms: model, our_pubkey: alice.pubkey, evs: [charlie_to_alice])

        XCTAssertEqual(model.dms.count, 4)
        XCTAssertEqual(model.dms[0].pubkey, charlie.pubkey)

        let bob_to_alice_3 = create_dm("hi alice 3", to_pk: alice.pubkey, tags: [["p", alice.pubkey]], keypair: bob, created_at: now + 25)!
        handle_incoming_dms(debouncer: debouncer, prev_events: notif, dms: model, our_pubkey: alice.pubkey, evs: [bob_to_alice_3])

        XCTAssertEqual(model.dms.count, 4)
        XCTAssertEqual(model.dms[0].pubkey, bob.pubkey)

        let charlie_to_alice_2 = create_dm("hi alice 2", to_pk: alice.pubkey, tags: [["p", alice.pubkey]], keypair: charlie, created_at: now + 30)!
        handle_incoming_dms(debouncer: debouncer, prev_events: notif, dms: model, our_pubkey: alice.pubkey, evs: [charlie_to_alice_2])

        XCTAssertEqual(model.dms.count, 4)
        XCTAssertEqual(model.dms[0].pubkey, charlie.pubkey)
    }

}
