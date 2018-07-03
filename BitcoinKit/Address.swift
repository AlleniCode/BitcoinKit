//
//  Address.swift
//  BitcoinKit
//
//  Created by Kishikawa Katsumi on 2018/01/31.
//  Copyright © 2018 Kishikawa Katsumi. All rights reserved.
//

import Foundation

// TODO: このクラスはPubkeyHash Addressにしか対応していない。ScriptHashとかPrivateとか対応しないなら名前がおかしい。
public protocol Address {
    var network: Network { get }
    var type: AddressType { get }
    var data: Data { get }
    var base58: String { get }
    var cashaddr: String { get }
}

public struct LegacyAddress: Address {
    public let network: Network
    public let type: AddressType
    public let data: Data
    public let base58: Base58Check
    public let cashaddr: String
    public let publicKey: Data?

    public typealias Base58Check = String

    public init(_ publicKey: PublicKey) {
        self.network = publicKey.network
        self.type = .pubkeyHash
        self.publicKey = publicKey.raw
        self.data = Crypto.sha256ripemd160(publicKey.raw)
        self.base58 = publicKey.toAddress()
        self.cashaddr = publicKey.toCashaddr()
    }

    public init(_ publicKey: HDPublicKey) {
        self.network = publicKey.network
        self.type = .pubkeyHash
        self.publicKey = publicKey.raw
        self.data = Crypto.sha256ripemd160(publicKey.raw)
        self.base58 = publicKey.toAddress()
        self.cashaddr = publicKey.toCashaddr()
    }

    public init(_ base58: Base58Check) throws {
        let raw = Base58.decode(base58)
        let checksum = raw.suffix(4)
        let pubKeyHash = raw.dropLast(4)
        let checksumConfirm = Crypto.sha256sha256(pubKeyHash).prefix(4)
        guard checksum == checksumConfirm else {
            throw AddressError.invalid
        }

        let network: Network
        let type: AddressType
        let addressPrefix = pubKeyHash[0]
        switch addressPrefix {
        case Network.mainnet.pubkeyhash:
            network = .mainnet
            type = .pubkeyHash
        case Network.testnet.pubkeyhash:
            network = .testnet
            type = .pubkeyHash
        case Network.mainnet.scripthash:
            network = .mainnet
            type = .scriptHash
        case Network.testnet.scripthash:
            network = .testnet
            type = .scriptHash
        default:
            // TODO: privatekey, xpriv, xpub
            throw AddressError.wrongNetwork
        }

        self.network = network
        self.type = type
        self.publicKey = nil
        self.data = pubKeyHash.dropFirst()
        self.base58 = base58

        // cashaddr
        switch type {
        case .pubkeyHash, .scriptHash:
            let payload = Data([type.versionByte160]) + self.data
            self.cashaddr = Bech32.encode(payload, prefix: network.scheme)
        default:
            self.cashaddr = ""
        }
    }
}

extension LegacyAddress: Equatable {
    // swiftlint:disable:next operator_whitespace
    public static func ==(lhs: LegacyAddress, rhs: LegacyAddress) -> Bool {
        return lhs.network == rhs.network && lhs.data == rhs.data && lhs.type == rhs.type
    }
}

extension LegacyAddress: CustomStringConvertible {
    public var description: String {
        return base58
    }
}

public struct Cashaddr: Address {
    public let network: Network
    public let type: AddressType
    public let data: Data
    public let base58: String
    public let cashaddr: Bech32Check
    public let publicKey: Data?

    public typealias Bech32Check = String

    public init(_ publicKey: PublicKey) {
        self.network = publicKey.network
        self.type = .pubkeyHash
        self.publicKey = publicKey.raw
        self.data = Crypto.sha256ripemd160(publicKey.raw)
        self.base58 = publicKey.toAddress()
        self.cashaddr = publicKey.toCashaddr()
    }

    public init(_ publicKey: HDPublicKey) {
        self.network = publicKey.network
        self.type = .pubkeyHash
        self.publicKey = publicKey.raw
        self.data = Crypto.sha256ripemd160(publicKey.raw)
        self.base58 = publicKey.toAddress()
        self.cashaddr = publicKey.toCashaddr()
    }

    // TODO: Bech32.decode
//    public init(_ bech32: Bech32Check) throws {
//        do {
//            let prefix, pubKeyHash = try Bech32.decode(bech32)
//        } catch {
//            throw AddressError.invalid
//        }
//        
//        let network: Network
//        let type: AddressType
//        let versionByte = pubKeyHash[0]
//        switch versionByte {
//        case 0:
//            type = .pubkeyHash
//        case 8:
//            type = .scriptHash
//        default:
//            throw AddressError.wrongNetwork
//        }
//        
//        self.network = network
//        self.type = type
//        self.publicKey = nil
//        self.data = pubKeyHash.dropFirst()
//        self.cashaddr = bech32
//        
//        // base58
//        self.base58 = publicKeyHashToAddress(Data([network.pubkeyhash]) + data)
//    }
}

extension Cashaddr: Equatable {
    // swiftlint:disable:next operator_whitespace
    public static func ==(lhs: Cashaddr, rhs: Cashaddr) -> Bool {
        return lhs.network == rhs.network && lhs.data == rhs.data && lhs.type == rhs.type
    }
}

extension Cashaddr: CustomStringConvertible {
    public var description: String {
        return cashaddr
    }
}

public enum AddressError: Error {
    case invalid
    case wrongNetwork
}
