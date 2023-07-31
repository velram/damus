//
//  damusTests.swift
//  damusTests
//
//  Created by William Casarin on 2022-04-01.
//

import XCTest
@testable import damus

class damusTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testRandomBytes() {
        let bytes = random_bytes(count: 32)
        
        print("testRandomBytes \(hex_encode(bytes))")
        XCTAssertEqual(bytes.count, 32)
    }
    
    func testTrimmingFunctions() {
        let txt = "   bobs   "
        
        XCTAssertEqual(trim_prefix(txt), "bobs   ")
        XCTAssertEqual(trim_suffix(txt), "   bobs")
    }
    
    func testParseMentionWithMarkdown() {
        let md = """
        Testing markdown in damus
        
        **bold**

        _italics_

        `monospace`

        # h1

        ## h2

        ### h3

        * list1
        * list2

        > some awesome quote

        [my website](https://jb55.com)
        """
        
        let parsed = parse_note_content(content: .content(md)).blocks

        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed.count, 3)
        XCTAssertNotNil(parsed[0].is_text)
        XCTAssertNotNil(parsed[1].is_url)
        XCTAssertNotNil(parsed[2].is_text)
    }

    func testStringArrayStorage() {
        let key = "test_key_string_values"
        let scoped_key = setting_property_key(key: key)

        let res = setting_set_property_value(scoped_key: scoped_key, old_value: [], new_value: ["a"])
        XCTAssertEqual(res, ["a"])

        let got = setting_get_property_value(key: key, scoped_key: scoped_key, default_value: [String]())
        XCTAssertEqual(got, ["a"])

        _ = setting_set_property_value(scoped_key: scoped_key, old_value: got, new_value: ["a", "b", "c"])
        let got2 = setting_get_property_value(key: key, scoped_key: scoped_key, default_value: [String]())
        XCTAssertEqual(got2, ["a", "b", "c"])
    }

    func testParseUrlUpper() {
        let parsed = parse_note_content(content: .content("a HTTPS://jb55.COM b")).blocks

        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed.count, 3)
        XCTAssertEqual(parsed[1].is_url?.absoluteString, "HTTPS://jb55.COM")
    }
    
    func testBech32Url()  {
        let parsed = decode_nostr_uri("nostr:npub1xtscya34g58tk0z605fvr788k263gsu6cy9x0mhnm87echrgufzsevkk5s")
        
        let pk = Pubkey(hex:"32e1827635450ebb3c5a7d12c1f8e7b2b514439ac10a67eef3d9fd9c5c68e245")!
        XCTAssertEqual(parsed, .ref(.pubkey(pk)))
    }
    
    func testSaveRelayFilters() {
        var filters = Set<RelayFilter>()
        
        let filter1 = RelayFilter(timeline: .search, relay_id: "wss://abc.com")
        let filter2 = RelayFilter(timeline: .home, relay_id: "wss://abc.com")
        filters.insert(filter1)
        filters.insert(filter2)
        
        save_relay_filters(test_pubkey, filters: filters)
        let loaded_filters = load_relay_filters(test_pubkey)!

        XCTAssertEqual(loaded_filters.count, 2)
        XCTAssertTrue(loaded_filters.contains(filter1))
        XCTAssertTrue(loaded_filters.contains(filter2))
        XCTAssertEqual(filters, loaded_filters)
    }
    
    func testParseUrl() {
        let parsed = parse_note_content(content: .content("a https://jb55.com b")).blocks

        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed.count, 3)
        XCTAssertEqual(parsed[1].is_url?.absoluteString, "https://jb55.com")
    }
    
    func testParseUrlEnd() {
        let parsed = parse_note_content(content: .content("a https://jb55.com")).blocks

        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed.count, 2)
        XCTAssertEqual(parsed[0].is_text, "a ")
        XCTAssertEqual(parsed[1].is_url?.absoluteString, "https://jb55.com")
    }
    
    func testParseUrlStart() {
        let parsed = parse_note_content(content: .content("https://jb55.com br")).blocks

        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed.count, 2)
        XCTAssertEqual(parsed[0].is_url?.absoluteString, "https://jb55.com")
        XCTAssertEqual(parsed[1].is_text, " br")
    }
    
    func testNoParseUrlWithOnlyWhitespace() {
        let testString = "https://  "
        let parsed = parse_note_content(content: .content(testString)).blocks

        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed[0].is_text, testString)
    }
    
    func testNoParseUrlTrailingCharacters() {
        let testString = "https://foo.bar, "
        let parsed = parse_note_content(content: .content(testString)).blocks

        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed[0].is_url?.absoluteString, "https://foo.bar")
    }


    /*
    func testParseMentionBlank() {
        let parsed = parse_note_content(content: "", tags: [["e", "event_id"]]).blocks
        
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed.count, 0)
    }
     */

    func testMakeHashtagPost() {
        let post = NostrPost(content: "#damus some content #bitcoin derp", references: [])
        let ev = post_to_event(post: post, keypair: test_keypair_full)!

        XCTAssertEqual(ev.tags.count, 2)
        XCTAssertEqual(ev.content, "#damus some content #bitcoin derp")
        XCTAssertEqual(ev.tags[0][0].string(), "t")
        XCTAssertEqual(ev.tags[0][1].string(), "damus")
        XCTAssertEqual(ev.tags[1][0].string(), "t")
        XCTAssertEqual(ev.tags[1][1].string(), "bitcoin")

    }
    func testParseMentionOnlyText() {
        let tags = [["e", "event_id"]]
        let ev = NostrEvent(content: "there is no mention here", keypair: test_keypair, tags: tags)!
        let parsed = parse_note_content(content: .note(ev)).blocks

        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed.count, 1)
        XCTAssertEqual(parsed[0].is_text, "there is no mention here")
        
        guard case .text(let txt) = parsed[0] else {
            XCTAssertTrue(false)
            return
        }
        
        XCTAssertEqual(txt, "there is no mention here")
    }

}
