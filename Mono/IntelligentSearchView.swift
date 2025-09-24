//
//  IntelligentSearchView.swift
//  Mono
//
//  Intelligent Search User Interface - Semantic Search and Results
//

import SwiftUI

struct IntelligentSearchView: View {
    @StateObject private var searchManager = IntelligentSearchManager.shared
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var searchFilters = SearchFilters()
    @State private var selectedResult: SearchResult?
    @State private var showingResultDetail = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Header
                searchHeader

                // Search Results or Empty State
                if searchManager.isSearching {
                    searchingView
                } else if searchManager.searchResults.isEmpty && !searchText.isEmpty {
                    emptyResultsView
                } else if searchManager.searchResults.isEmpty {
                    emptyStateView
                } else {
                    searchResultsList
                }
            }
            .navigationTitle("Intelligent Search")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingFilters) {
                SearchFiltersView(filters: $searchFilters)
            }
            .sheet(isPresented: $showingResultDetail) {
                if let result = selectedResult {
                    SearchResultDetailView(result: result)
                }
            }
            .onAppear {
                // Check for pending search query
                if let pendingQuery = UserDefaults.standard.string(forKey: "pendingSearchQuery") {
                    searchText = pendingQuery
                    UserDefaults.standard.removeObject(forKey: "pendingSearchQuery")
                    performSearch()
                }
            }
        }
    }
    
    private var searchHeader: some View {
        VStack(spacing: 16) {
            // Main Search Bar
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search by meaning, concepts, or keywords...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onSubmit {
                            performSearch()
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Filters Button
                Button(action: { showingFilters = true }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            
            // Search Suggestions
            if !searchManager.suggestedQueries.isEmpty && searchText.isEmpty {
                searchSuggestions
            }
            
            // Search History
            if !searchManager.searchHistory.isEmpty && searchText.isEmpty {
                searchHistory
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private var searchSuggestions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Suggested Searches")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(searchManager.suggestedQueries, id: \.self) { suggestion in
                        Button(suggestion) {
                            searchText = suggestion
                            performSearch()
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.systemBlue).opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var searchHistory: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Searches")
                .font(.caption)
                .foregroundColor(.secondary)
            
            LazyVStack(spacing: 4) {
                ForEach(searchManager.searchHistory.prefix(3), id: \.self) { query in
                    Button(action: {
                        searchText = query
                        performSearch()
                    }) {
                        HStack {
                            Image(systemName: "clock")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(query)
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var searchingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Searching across conversations and memory palace...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Results Found")
                .font(.headline)
            
            Text("Try different keywords or search by concepts and themes")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 64))
                .foregroundColor(.purple)
            
            VStack(spacing: 8) {
                Text("Intelligent Search")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Search by meaning, not just keywords")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                SearchFeatureRow(
                    icon: "magnifyingglass.circle",
                    title: "Semantic Search",
                    description: "Find concepts and ideas across all conversations"
                )
                
                SearchFeatureRow(
                    icon: "brain.head.profile",
                    title: "Memory Palace",
                    description: "Search your curated knowledge and insights"
                )
                
                SearchFeatureRow(
                    icon: "link.circle",
                    title: "Connected Ideas",
                    description: "Discover related topics and connections"
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Results Header
                HStack {
                    Text("\(searchManager.searchResults.count) results")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Menu("Sort") {
                        Button("Relevance") { /* Sort by relevance */ }
                        Button("Date") { /* Sort by date */ }
                        Button("Type") { /* Sort by type */ }
                    }
                    .font(.caption)
                }
                .padding(.horizontal)
                
                // Results
                ForEach(searchManager.searchResults) { result in
                    SearchResultCard(result: result) {
                        selectedResult = result
                        showingResultDetail = true
                    }
                }
            }
            .padding()
        }
    }
    
    private func performSearch() {
        Task {
            await searchManager.performIntelligentSearch(query: searchText, filters: searchFilters)
        }
    }
}

// MARK: - Supporting Views

struct SearchFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct SearchResultCard: View {
    let result: SearchResult
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    resultTypeIcon
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        Text(resultTypeDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Relevance Score
                    Text("\(Int(result.relevanceScore * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemBlue).opacity(0.1))
                        .cornerRadius(4)
                }
                
                // Content Snippet
                Text(result.snippet)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                // Highlights
                if !result.highlights.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(result.highlights, id: \.self) { highlight in
                                Text(highlight)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(.systemYellow).opacity(0.3))
                                    .cornerRadius(4)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Footer
                HStack {
                    Text(result.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var resultTypeIcon: some View {
        Group {
            switch result.type {
            case .conversation:
                Image(systemName: "message.circle")
                    .foregroundColor(.blue)
            case .memoryNode:
                Image(systemName: result.memoryNodeType?.icon ?? "brain.head.profile")
                    .foregroundColor(result.memoryNodeType?.color ?? .purple)
            case .semanticMatch:
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.green)
            }
        }
        .font(.title3)
    }
    
    private var resultTypeDescription: String {
        switch result.type {
        case .conversation:
            return "Conversation"
        case .memoryNode:
            return "Memory Palace • \(result.memoryNodeType?.rawValue.capitalized ?? "Node")"
        case .semanticMatch:
            return "Semantic Match"
        }
    }
}

// MARK: - Search Filters View

struct SearchFiltersView: View {
    @Binding var filters: SearchFilters
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Date Range") {
                    DatePicker("Start Date", selection: Binding(
                        get: { filters.startDate ?? Date().addingTimeInterval(-30*24*60*60) },
                        set: { filters.startDate = $0 }
                    ), displayedComponents: .date)

                    DatePicker("End Date", selection: Binding(
                        get: { filters.endDate ?? Date() },
                        set: { filters.endDate = $0 }
                    ), displayedComponents: .date)

                    Button("Clear Date Filter") {
                        filters.startDate = nil
                        filters.endDate = nil
                    }
                    .foregroundColor(.red)
                }

                Section("Memory Node Types") {
                    ForEach(MemoryNodeType.allCases, id: \.self) { nodeType in
                        HStack {
                            Image(systemName: nodeType.icon)
                                .foregroundColor(nodeType.color)

                            Text(nodeType.rawValue.capitalized)

                            Spacer()

                            if filters.memoryNodeTypes?.contains(nodeType) == true {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleNodeType(nodeType)
                        }
                    }
                }

                Section("Relevance") {
                    HStack {
                        Text("Minimum Relevance")
                        Spacer()
                        Text("\(Int(filters.minRelevanceScore * 100))%")
                            .foregroundColor(.secondary)
                    }

                    Slider(value: $filters.minRelevanceScore, in: 0...1, step: 0.1)
                }
            }
            .navigationTitle("Search Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        filters = SearchFilters()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func toggleNodeType(_ nodeType: MemoryNodeType) {
        if filters.memoryNodeTypes == nil {
            filters.memoryNodeTypes = []
        }

        if filters.memoryNodeTypes!.contains(nodeType) {
            filters.memoryNodeTypes!.removeAll { $0 == nodeType }
        } else {
            filters.memoryNodeTypes!.append(nodeType)
        }
    }
}

// MARK: - Search Result Detail View

struct SearchResultDetailView: View {
    let result: SearchResult
    @Environment(\.dismiss) private var dismiss
    @StateObject private var dataManager = DataManager.shared

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    resultHeader

                    // Content
                    resultContent

                    // Context
                    contextSection

                    // Actions
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Search Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var resultHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Group {
                    switch result.type {
                    case .conversation:
                        Image(systemName: "message.circle")
                            .foregroundColor(.blue)
                    case .memoryNode:
                        Image(systemName: result.memoryNodeType?.icon ?? "brain.head.profile")
                            .foregroundColor(result.memoryNodeType?.color ?? .purple)
                    case .semanticMatch:
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.green)
                    }
                }
                .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(resultTypeText)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(result.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(result.relevanceScore * 100))%")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)

                    Text("Relevance")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Text(result.timestamp, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var resultContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Content")
                .font(.headline)

            Text(result.content)
                .font(.body)
                .textSelection(.enabled)

            if !result.highlights.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Highlighted Terms")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(result.highlights, id: \.self) { highlight in
                            Text(highlight)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemYellow).opacity(0.3))
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }

    private var contextSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Context")
                .font(.headline)

            if let conversation = dataManager.conversations.first(where: { $0.id == result.sourceConversationId }) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("From Conversation:")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(conversation.title)
                        .font(.body)
                        .foregroundColor(.blue)

                    Text("Created \(conversation.createdAt, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBlue).opacity(0.1))
                .cornerRadius(8)
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: openSourceConversation) {
                HStack {
                    Image(systemName: "message.circle")
                    Text("Open Source Conversation")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBlue))
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            if result.type == .memoryNode {
                Button(action: openMemoryPalace) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                        Text("View in Memory Palace")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemPurple))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
    }

    private var resultTypeText: String {
        switch result.type {
        case .conversation:
            return "Conversation Message"
        case .memoryNode:
            return "Memory Palace • \(result.memoryNodeType?.rawValue.capitalized ?? "Node")"
        case .semanticMatch:
            return "Semantic Match"
        }
    }

    private func openSourceConversation() {
        // Navigate to source conversation
        dismiss()
    }

    private func openMemoryPalace() {
        // Navigate to memory palace
        dismiss()
    }
}
