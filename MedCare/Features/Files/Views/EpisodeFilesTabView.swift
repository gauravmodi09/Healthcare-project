import SwiftUI

/// Files tab content for EpisodeDetailView — shows all documents for an episode
struct EpisodeFilesTabView: View {
    let episode: Episode
    @Environment(DataService.self) private var dataService
    @State private var selectedType: ImageType?
    @State private var showAddDocument = false

    private var documents: [EpisodeImage] {
        dataService.documentsForEpisode(episode, filterType: selectedType)
    }

    private let columns = [
        GridItem(.flexible(), spacing: MCSpacing.sm),
        GridItem(.flexible(), spacing: MCSpacing.sm)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: MCSpacing.md) {
            // Category filter
            categoryFilter

            if documents.isEmpty {
                emptyState
            } else {
                // Document count
                HStack {
                    Text("\(documents.count) document\(documents.count == 1 ? "" : "s")")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textSecondary)
                    Spacer()
                }
                .padding(.horizontal, MCSpacing.screenPadding)

                // Document grid
                LazyVGrid(columns: columns, spacing: MCSpacing.sm) {
                    ForEach(documents, id: \.id) { doc in
                        NavigationLink(value: DocumentNavID(id: doc.id)) {
                            DocumentThumbnailCard(document: doc)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, MCSpacing.screenPadding)
            }

            Spacer(minLength: MCSpacing.xxl)
        }
        .padding(.vertical, MCSpacing.md)
        .overlay(alignment: .bottomTrailing) {
            addButton
        }
        .sheet(isPresented: $showAddDocument) {
            AddDocumentView(episode: episode)
        }
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MCSpacing.xs) {
                FilterChip(title: "All", isSelected: selectedType == nil) {
                    selectedType = nil
                }

                ForEach(documentTypesInEpisode(), id: \.self) { type in
                    FilterChip(title: type.rawValue, isSelected: selectedType == type, color: Color(hex: type.displayColor)) {
                        selectedType = type
                    }
                }
            }
            .padding(.horizontal, MCSpacing.screenPadding)
        }
    }

    private func documentTypesInEpisode() -> [ImageType] {
        let types = Set(episode.images.map { $0.imageType })
        return ImageType.allCases.filter { types.contains($0) }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: MCSpacing.md) {
            Spacer()
            Image(systemName: "folder")
                .font(.system(size: 48))
                .foregroundStyle(MCColors.textTertiary)
            Text("No Files Yet")
                .font(MCTypography.headline)
                .foregroundStyle(MCColors.textSecondary)
            Text("Add prescriptions, reports, scans, and other documents")
                .font(MCTypography.footnote)
                .foregroundStyle(MCColors.textTertiary)
                .multilineTextAlignment(.center)

            MCPrimaryButton("Add Document", icon: "plus") {
                showAddDocument = true
            }
            .padding(.horizontal, MCSpacing.xxl)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            showAddDocument = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(MCColors.primaryTeal)
                .clipShape(Circle())
                .shadow(color: MCColors.primaryTeal.opacity(0.3), radius: 8, y: 4)
        }
        .padding(.trailing, MCSpacing.screenPadding)
        .padding(.bottom, MCSpacing.md)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = MCColors.primaryTeal
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(MCTypography.caption)
                .foregroundStyle(isSelected ? .white : MCColors.textPrimary)
                .padding(.horizontal, MCSpacing.sm)
                .padding(.vertical, MCSpacing.xxs + 2)
                .background(isSelected ? color : MCColors.backgroundLight)
                .clipShape(Capsule())
        }
    }
}
