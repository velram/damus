//
//  Keys.swift
//  damus
//
//  Created by William Casarin on 2022-05-21.
//

import Foundation
import secp256k1

let PUBKEY_HRP = "npub"
let ANON_PUBKEY = "anon"

struct FullKeypair: Equatable {
    let pubkey: Pubkey
    let privkey: Privkey

    func to_keypair() -> Keypair {
        return Keypair(pubkey: pubkey, privkey: privkey)
    }
}

struct Keypair {
    let pubkey: Pubkey
    let privkey: Privkey?
    let pubkey_bech32: String
    let privkey_bech32: String?

    func to_full() -> FullKeypair? {
        guard let privkey = self.privkey else {
            return nil
        }
        
        return FullKeypair(pubkey: pubkey, privkey: privkey)
    }

    static func just_pubkey(_ pk: Pubkey) -> Keypair {
        return .init(pubkey: pk, privkey: nil)
    }

    init(pubkey: Pubkey, privkey: Privkey?) {
        self.pubkey = pubkey
        self.privkey = privkey
        self.pubkey_bech32 = bech32_pubkey(pubkey) ?? pubkey
        self.privkey_bech32 = privkey.flatMap { bech32_privkey($0) }
    }
}

enum Bech32Key {
    case pub(Pubkey)
    case sec(Privkey)
}

func decode_bech32_key(_ key: String) -> Bech32Key? {
    guard let decoded = try? bech32_decode(key) else {
        return nil
    }
    
    let hexed = hex_encode(decoded.data)
    if decoded.hrp == "npub" {
        return .pub(hexed)
    } else if decoded.hrp == "nsec" {
        return .sec(hexed)
    }
    
    return nil
}

func bech32_privkey(_ privkey: String) -> String? {
    guard let bytes = hex_decode(privkey) else {
        return nil
    }
    return bech32_encode(hrp: "nsec", bytes)
}

func bech32_pubkey(_ pubkey: String) -> String? {
    guard let bytes = hex_decode(pubkey) else {
        return nil
    }
    return bech32_encode(hrp: "npub", bytes)
}

func bech32_pubkey_decode(_ pubkey: String) -> String? {
    guard let decoded = try? bech32_decode(pubkey), decoded.hrp == "npub" else {
        return nil
    }

    return hex_encode(decoded.data)
}

func bech32_nopre_pubkey(_ pubkey: String) -> String? {
    guard let bytes = hex_decode(pubkey) else {
        return nil
    }
    return bech32_encode(hrp: "", bytes)
}

func bech32_note_id(_ evid: String) -> String? {
    guard let bytes = hex_decode(evid) else {
        return nil
    }
    return bech32_encode(hrp: "note", bytes)
}

func generate_new_keypair() -> Keypair {
    let key = try! secp256k1.Signing.PrivateKey()
    let privkey = hex_encode(key.rawRepresentation)
    let pubkey = hex_encode(Data(key.publicKey.xonly.bytes))
    return Keypair(pubkey: pubkey, privkey: privkey)
}

func privkey_to_pubkey_raw(sec: [UInt8]) -> Pubkey? {
    guard let key = try? secp256k1.Signing.PrivateKey(rawRepresentation: sec) else {
        return nil
    }
    return hex_encode(Data(key.publicKey.xonly.bytes))
}

func privkey_to_pubkey(privkey: String) -> String? {
    guard let sec = hex_decode(privkey) else { return nil }
    return privkey_to_pubkey_raw(sec: sec)
}

func save_pubkey(pubkey: Pubkey) {
    UserDefaults.standard.set(pubkey.hex(), forKey: "pubkey")
}

enum Keys {
    @KeychainStorage(account: "privkey")
    static var privkey: String?
}

func save_privkey(privkey: Privkey) throws {
    Keys.privkey = privkey.hex()
}

func clear_saved_privkey() throws {
    Keys.privkey = nil
}

func clear_saved_pubkey() {
    UserDefaults.standard.removeObject(forKey: "pubkey")
}

func save_keypair(pubkey: Pubkey, privkey: Privkey) throws {
    save_pubkey(pubkey: pubkey)
    try save_privkey(privkey: privkey)
}

func clear_keypair() throws {
    try clear_saved_privkey()
    clear_saved_pubkey()
}

func get_saved_keypair() -> Keypair? {
    do {
        try removePrivateKeyFromUserDefaults()
        
        return get_saved_pubkey().flatMap { pubkey in
            let privkey = get_saved_privkey()
            return Keypair(pubkey: pubkey, privkey: privkey)
        }
    } catch {
        return nil
    }
}

func get_saved_pubkey() -> String? {
    return UserDefaults.standard.string(forKey: "pubkey")
}

func get_saved_privkey() -> String? {
    let mkey = Keys.privkey
    return mkey.map { $0.trimmingCharacters(in: .whitespaces) }
}

/**
 Detects whether a string might contain an nsec1 prefixed private key.
 It does not determine if it's the current user's private key and does not verify if it is properly encoded or has the right length.
 */
func contentContainsPrivateKey(_ content: String) -> Bool {
    if #available(iOS 16.0, *) {
        return content.contains(/nsec1[02-9ac-z]+/)
    } else {
        let regex = try! NSRegularExpression(pattern: "nsec1[02-9ac-z]+")
        return (regex.firstMatch(in: content, range: NSRange(location: 0, length: content.count)) != nil)
    }

}

fileprivate func removePrivateKeyFromUserDefaults() throws {
    guard let privKey = UserDefaults.standard.string(forKey: "privkey") else { return }
    try save_privkey(privkey: privKey)
    UserDefaults.standard.removeObject(forKey: "privkey")
}
