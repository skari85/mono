//  SeededRandom.swift
//  Mono
//
//  Created by Augment Agent on 2025-08-09.
//

import Foundation

// MARK: - Seeded RNG for deterministic visuals
public struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    public init(seed: UInt64) { self.state = seed &* 0x9E3779B97F4A7C15 }
    public mutating func next() -> UInt64 {
        // SplitMix64
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

