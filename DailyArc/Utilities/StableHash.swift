import CryptoKit
import Foundation

/// Deterministic hash for any string — returns a stable UInt across app launches.
/// Uses SHA256 truncation for consistency.
/// Used by: celebration variant selection, streak loss variant selection, journaling prompts.
enum StableHash {
    static func hash(_ input: String) -> UInt {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.prefix(4).reduce(0) { $0 << 8 | UInt($1) }
    }
}
