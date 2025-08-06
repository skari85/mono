//
//  DataManager.swift
//  Mono
//
//  Created by Georg albert on 6.8.2025.
//

import Foundation
import SwiftData

class DataManager {
    static let shared = DataManager()
    
    lazy var modelContainer: ModelContainer = {
        do {
            let schema = Schema([
                ChatMessage.self,
                CassetteMemory.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            print("Failed to create ModelContainer: \(error)")
            // Fallback: try with just ChatMessage if there's a schema conflict
            do {
                return try ModelContainer(for: ChatMessage.self)
            } catch {
                fatalError("Failed to create fallback ModelContainer: \(error)")
            }
        }
    }()
    
    private init() {}
}
