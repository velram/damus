//
//  Privkey.swift
//  damus
//
//  Created by William Casarin on 2023-07-30.
//

import Foundation

struct Privkey: IdType {
    let id: Data

    var nsec: String {
        bech32_privkey(self)
    }

    init?(hex: String) {
        guard let id = hex_decode_id(hex) else {
            return nil
        }
        self.init(id)
    }

    init(_ data: Data) {
        self.id = data
    }
}


