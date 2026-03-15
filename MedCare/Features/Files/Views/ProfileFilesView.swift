import SwiftUI
import SwiftData

/// Profile-level file view — aggregates all documents across all episodes
struct ProfileFilesView: View {
    @Environment(DataService.self) private var dataService
    @Query private var users: [User]
    @State private var selectedType: ImageType?

    private var activeProfile: UserProfile? { users.first?.activeProfile }

    private var documents: [EpisodeImage] {
        guard let profile = activeProfile else { return [] }
        return dataService.allDocumentsForProfile(profile, filterType: selectedType)
    }

    private let columns = [
        GridItem(.flexible(), spacing: MCSpacing.sm),
        GridItem(.flexible(), spacing: MCSpacing.sm)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: MCSpacing.md) {
                // Summary counts
                if let profile = activeProfile {
                    summarySection(profile)
                }

                // Category filter
                categoryFilter

                // Document grid
                if documents.isEmpty {
                    emptyState
                } else {
                    Text("\(documents.count) document\(documents.count == 1 ? "" : "s")")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, MCSpacing.screenPadding)

                    LazyVGrid(columns: columns, spacing: MCSpacing.sm) {
                        ForEach(documents, id: \.id) { doc in
                            NavigationLink(value: DocumentNavID(id: doc.id)) {
                                DocumentThumbnailCard(document: doc, showEpisodeName: true)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, MCSpacing.screenPadding)
                }
            }
            .padding(.vertical, MCSpacing.md)
        }
        .background(MCColors.backgroundLight)
        .navigationTitle("All Documents")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: DocumentNavID.self) { nav in
            DocumentDetailView(documentId: nav.id)
        }
    }

    // MARK: - Summary

    private func summarySection(_ profile: UserProfile) -> some View {
        let counts = dataService.documentCountsByType(for: profile)
        let total = counts.values.reduce(0, +)

        return MCCard {
            VStack(alignment: .leading, spacing: MCSpacing.sm) {
                HStack {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(MCColors.primaryTeal)
                    Text("Document Summary")
                        .font(MCTypography.headline)
                    Spacer()
                    Text("\(total) total")
                        .font(MCTypography.subheadline)
                        .foregroundStyle(MCColors.primaryTeal)
                }

                if !counts.isEmpty {
                    FlowLayout(spacing: MCSpacing.xs) {
                        ForEach(counts.sorted(by: { $0.value > $1.value }), id: \.key) { type, count in
                            HStack(spacing: MCSpacing.xxs) {
                                Image(systemName: type.icon)
                                    .font(.system(size: 10))
                                Text("\(count) \(type.rawValue)")
                                    .font(MCTypography.caption)
                            }
                            .foregroundStyle(Color(hex: type.displayColor))
                            .padding(.horizontal, MCSpacing.xs)
                            .padding(.vertical, 3)
                            .background(Color(hex: type.displayColor).opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MCSpacing.xs) {
                FilterChip(title: "All", isSelected: selectedType == nil) {
                    selectedType = nil
                }

                ForEach(availableTypes(), id: \.self) { type in
                    FilterChip(title: type.rawValue, isSelected: selectedType == type, color: Color(hex: type.displayColor)) {
                        selectedType = type
                    }
                }
            }
            .padding(.horizontal, MCSpacing.screenPadding)
        }
    }

    private func availableTypes() -> [ImageType] {
        guard let profile = activeProfile else { return [] }
        let types = Set(profile.episodes.flatMap { $0.images }.map { $0.imageType })
        return ImageType.allCases.filter { types.contains($0) }
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: MCSpacing.md) {
            Spacer().frame(height: MCSpacing.xxl)
            Image(systemName: "folder")
                .font(.system(size: 48))
                .foregroundStyle(MCColors.textTertiary)
            Text("No Documents")
                .font(MCTypography.headline)
                .foregroundStyle(MCColors.textSecondary)
            Text("Documents will appear here when you add them to your episodes")
                .font(MCTypography.footnote)
                .foregroundStyle(MCColors.textTertiary)
                .multilineTextAlignment(.center)
            Spacer().frame(height: MCSpacing.xxl)
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }
}
