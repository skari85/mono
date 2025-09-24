//
//  MemoryPalaceView.swift
//  Mono
//
//  Memory Palace User Interface - Browse and Explore Knowledge
//

import SwiftUI

struct MemoryPalaceView: View {
    @StateObject private var memoryManager = MemoryPalaceManager.shared
    @State private var selectedTab = 0
    @State private var selectedNode: MemoryNode?
    @State private var showingNodeDetail = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                memoryPalaceHeader
                
                // Tab Selection
                tabSelector
                
                // Content
                Group {
                    switch selectedTab {
                    case 0:
                        MemoryOverviewView(selectedNode: $selectedNode, showingDetail: $showingNodeDetail)
                    case 1:
                        Text("Knowledge Graph View")
                            .foregroundColor(.secondary)
                    case 2:
                        Text("Topic Clusters View")
                            .foregroundColor(.secondary)
                    case 3:
                        Text("Memory Timeline View")
                            .foregroundColor(.secondary)
                    default:
                        MemoryOverviewView(selectedNode: $selectedNode, showingDetail: $showingNodeDetail)
                    }
                }
            }
            .navigationTitle("Memory Palace")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingNodeDetail) {
                if let node = selectedNode {
                    MemoryNodeDetailView(node: node)
                }
            }
        }
    }
    
    private var memoryPalaceHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Memory Palace")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(memoryManager.getAllMemoryNodes().count) knowledge nodes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if memoryManager.isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search your knowledge...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(Array(zip(["Overview", "Graph", "Topics", "Timeline"].indices, ["Overview", "Graph", "Topics", "Timeline"])), id: \.0) { index, title in
                Button(action: { selectedTab = index }) {
                    VStack(spacing: 4) {
                        Text(title)
                            .font(.caption)
                            .fontWeight(selectedTab == index ? .semibold : .regular)
                        
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(selectedTab == index ? .purple : .clear)
                    }
                }
                .foregroundColor(selectedTab == index ? .purple : .secondary)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .background(Color(.systemBackground))
    }
}

// MARK: - Memory Overview

struct MemoryOverviewView: View {
    @StateObject private var memoryManager = MemoryPalaceManager.shared
    @Binding var selectedNode: MemoryNode?
    @Binding var showingDetail: Bool
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Stats Cards
                statsSection
                
                // Recent Nodes
                recentNodesSection
                
                // Node Types Overview
                nodeTypesSection
            }
            .padding()
        }
    }
    
    private var statsSection: some View {
        VStack(spacing: 12) {
            Text("Knowledge Overview")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                StatCard(
                    title: "Total Nodes",
                    value: "\(memoryManager.getAllMemoryNodes().count)",
                    icon: "brain.head.profile",
                    color: .purple
                )
                
                StatCard(
                    title: "Connections",
                    value: "\(memoryManager.knowledgeGraph.connections.count)",
                    icon: "link.circle",
                    color: .blue
                )
                
                StatCard(
                    title: "Topics",
                    value: "\(memoryManager.getTopicClusters().count)",
                    icon: "tag.circle",
                    color: .green
                )
            }
        }
    }
    
    private var recentNodesSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Recent Insights")
                    .font(.headline)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to timeline view
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(memoryManager.getRecentNodes(limit: 5)) { node in
                    MemoryNodeCard(node: node) {
                        selectedNode = node
                        showingDetail = true
                    }
                }
            }
        }
    }
    
    private var nodeTypesSection: some View {
        VStack(spacing: 12) {
            Text("Knowledge Types")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(MemoryNodeType.allCases, id: \.self) { nodeType in
                    let nodes = memoryManager.getNodesByType(nodeType)
                    
                    NodeTypeCard(
                        nodeType: nodeType,
                        count: nodes.count
                    ) {
                        // Show nodes of this type
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct MemoryNodeCard: View {
    let node: MemoryNode
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 12) {
                // Node Type Icon
                Image(systemName: node.nodeType.icon)
                    .font(.title3)
                    .foregroundColor(node.nodeType.color)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(node.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Text(node.summary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    HStack {
                        Text(node.createdAt, style: .relative)
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Spacer()

                        if !node.connections.isEmpty {
                            HStack(spacing: 2) {
                                Image(systemName: "link")
                                    .font(.caption2)
                                Text("\(node.connections.count)")
                                    .font(.caption2)
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NodeTypeCard: View {
    let nodeType: MemoryNodeType
    let count: Int
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: nodeType.icon)
                    .font(.title2)
                    .foregroundColor(nodeType.color)

                Text("\(count)")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(nodeType.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(nodeType.color.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MemoryNodeDetailView: View {
    let node: MemoryNode
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: node.nodeType.icon)
                                .font(.title2)
                                .foregroundColor(node.nodeType.color)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(node.nodeType.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text(node.title)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }

                            Spacer()
                        }

                        Text(node.summary)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(node.nodeType.color.opacity(0.1))
                    .cornerRadius(12)

                    // Content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Content")
                            .font(.headline)

                        Text(node.content)
                            .font(.body)
                    }
                }
                .padding()
            }
            .navigationTitle("Memory Node")
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
}
