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
                        KnowledgeGraphView(selectedNode: $selectedNode, showingDetail: $showingNodeDetail)
                    case 2:
                        TopicClustersView(selectedNode: $selectedNode, showingDetail: $showingNodeDetail)
                    case 3:
                        MemoryTimelineView(selectedNode: $selectedNode, showingDetail: $showingNodeDetail)
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

// MARK: - Knowledge Graph View

struct KnowledgeGraphView: View {
    @StateObject private var memoryManager = MemoryPalaceManager.shared
    @Binding var selectedNode: MemoryNode?
    @Binding var showingDetail: Bool
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Graph Overview
                VStack(alignment: .leading, spacing: 12) {
                    Text("Knowledge Connections")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if memoryManager.knowledgeGraph.connections.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "link")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            
                            Text("No connections yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("Start having conversations to build your knowledge graph")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        // Connection List
                        LazyVStack(spacing: 8) {
                            ForEach(Array(memoryManager.knowledgeGraph.connections.values), id: \.id) { connection in
                                ConnectionCard(connection: connection) {
                                    if let node = memoryManager.getMemoryNode(id: connection.sourceNodeId) {
                                        selectedNode = node
                                        showingDetail = true
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Node Network Visualization
                VStack(alignment: .leading, spacing: 12) {
                    Text("Node Network")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Simple network visualization
                    NetworkVisualizationView(
                        nodes: Array(memoryManager.knowledgeGraph.nodes.values),
                        connections: Array(memoryManager.knowledgeGraph.connections.values)
                    )
                    .frame(height: 300)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
    }
}

// MARK: - Topic Clusters View

struct TopicClustersView: View {
    @StateObject private var memoryManager = MemoryPalaceManager.shared
    @Binding var selectedNode: MemoryNode?
    @Binding var showingDetail: Bool
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Topic Clusters")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    let clusters = memoryManager.getTopicClusters()
                    
                    if clusters.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tag")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            
                            Text("No topics yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("Topics will be automatically organized as you have more conversations")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(Array(clusters.keys.sorted()), id: \.self) { topic in
                                TopicClusterCard(
                                    topic: topic,
                                    nodes: clusters[topic] ?? [],
                                    onNodeTap: { node in
                                        selectedNode = node
                                        showingDetail = true
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Memory Timeline View

struct MemoryTimelineView: View {
    @StateObject private var memoryManager = MemoryPalaceManager.shared
    @Binding var selectedNode: MemoryNode?
    @Binding var showingDetail: Bool
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Memory Timeline")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    let timelineNodes = memoryManager.knowledgeGraph.timeline
                        .compactMap { memoryManager.getMemoryNode(id: $0) }
                        .sorted { $0.createdAt > $1.createdAt }
                    
                    if timelineNodes.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "clock")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            
                            Text("No memories yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("Your conversation insights will appear here chronologically")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        // Group by date
                        let groupedNodes = Dictionary(grouping: timelineNodes) { node in
                            Calendar.current.startOfDay(for: node.createdAt)
                        }
                        
                        LazyVStack(spacing: 20) {
                            ForEach(Array(groupedNodes.keys.sorted(by: >)), id: \.self) { date in
                                TimelineDaySection(
                                    date: date,
                                    nodes: groupedNodes[date] ?? [],
                                    onNodeTap: { node in
                                        selectedNode = node
                                        showingDetail = true
                                    }
                                )
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Supporting Views

struct ConnectionCard: View {
    let connection: KnowledgeConnection
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Connection Type Icon
                Image(systemName: connectionIcon(for: connection.connectionType))
                    .font(.title3)
                    .foregroundColor(connectionColor(for: connection.connectionType))
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(connection.connectionType.rawValue.capitalized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(connection.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    HStack {
                        Text("Strength: \(Int(connection.strength * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(connection.createdAt, style: .relative)
                            .font(.caption2)
                            .foregroundColor(.secondary)
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
    
    private func connectionIcon(for type: ConnectionType) -> String {
        switch type {
        case .similar: return "equal.circle"
        case .causal: return "arrow.right.circle"
        case .contradictory: return "exclamationmark.circle"
        case .elaborative: return "plus.circle"
        case .temporal: return "clock.circle"
        case .thematic: return "tag.circle"
        }
    }
    
    private func connectionColor(for type: ConnectionType) -> Color {
        switch type {
        case .similar: return .blue
        case .causal: return .green
        case .contradictory: return .red
        case .elaborative: return .purple
        case .temporal: return .orange
        case .thematic: return .teal
        }
    }
}

struct TopicClusterCard: View {
    let topic: String
    let nodes: [MemoryNode]
    let onNodeTap: (MemoryNode) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(topic)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(nodes.count) nodes")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(nodes.prefix(5)) { node in
                    MemoryNodeCard(node: node, onTap: { onNodeTap(node) })
                }
                
                if nodes.count > 5 {
                    Button("View \(nodes.count - 5) more...") {
                        // Show all nodes for this topic
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TimelineDaySection: View {
    let date: Date
    let nodes: [MemoryNode]
    let onNodeTap: (MemoryNode) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(date, style: .date)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(nodes.count) insights")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(nodes) { node in
                    MemoryNodeCard(node: node, onTap: { onNodeTap(node) })
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct NetworkVisualizationView: View {
    let nodes: [MemoryNode]
    let connections: [KnowledgeConnection]
    
    var body: some View {
        Canvas { context, size in
            // Simple network visualization
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) * 0.3
            
            // Draw connections
            for connection in connections {
                if let sourceNode = nodes.first(where: { $0.id == connection.sourceNodeId }),
                   let targetNode = nodes.first(where: { $0.id == connection.targetNodeId }) {
                    
                    let sourceIndex = nodes.firstIndex(where: { $0.id == sourceNode.id }) ?? 0
                    let targetIndex = nodes.firstIndex(where: { $0.id == targetNode.id }) ?? 0
                    
                    let sourceAngle = Double(sourceIndex) * 2 * .pi / Double(nodes.count)
                    let targetAngle = Double(targetIndex) * 2 * .pi / Double(nodes.count)
                    
                    let sourcePoint = CGPoint(
                        x: center.x + radius * cos(sourceAngle),
                        y: center.y + radius * sin(sourceAngle)
                    )
                    
                    let targetPoint = CGPoint(
                        x: center.x + radius * cos(targetAngle),
                        y: center.y + radius * sin(targetAngle)
                    )
                    
                    // Draw connection line
                    context.stroke(
                        Path { path in
                            path.move(to: sourcePoint)
                            path.addLine(to: targetPoint)
                        },
                        with: .color(.secondary.opacity(0.3)),
                        lineWidth: CGFloat(connection.strength * 3)
                    )
                }
            }
            
            // Draw nodes
            for (index, node) in nodes.enumerated() {
                let angle = Double(index) * 2 * .pi / Double(nodes.count)
                let point = CGPoint(
                    x: center.x + radius * cos(angle),
                    y: center.y + radius * sin(angle)
                )
                
                // Draw node circle
                context.fill(
                    Circle().path(in: CGRect(
                        x: point.x - 8,
                        y: point.y - 8,
                        width: 16,
                        height: 16
                    )),
                    with: .color(node.nodeType.color)
                )
            }
        }
        .overlay(
            VStack {
                Text("Network Visualization")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(nodes.count) nodes, \(connections.count) connections")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        )
    }
}
