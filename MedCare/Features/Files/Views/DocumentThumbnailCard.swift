import SwiftUI

/// Reusable grid cell for displaying a document thumbnail
struct DocumentThumbnailCard: View {
    let document: EpisodeImage
    var showEpisodeName: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: MCSpacing.xs) {
            // Thumbnail area
            ZStack {
                RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall)
                    .fill(Color(hex: document.imageType.displayColor).opacity(0.08))

                if let localPath = document.localPath,
                   let uiImage = UIImage(contentsOfFile: localPath) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))
                } else {
                    // Placeholder with type icon
                    VStack(spacing: MCSpacing.xs) {
                        Image(systemName: document.imageType.icon)
                            .font(.system(size: 28))
                            .foregroundStyle(Color(hex: document.imageType.displayColor))
                        Text(document.imageType.rawValue)
                            .font(MCTypography.caption)
                            .foregroundStyle(Color(hex: document.imageType.displayColor).opacity(0.8))
                    }
                }
            }
            .frame(height: 100)
            .overlay(alignment: .topLeading) {
                MCBadge(
                    document.imageType.rawValue,
                    color: Color(hex: document.imageType.displayColor),
                    style: .soft
                )
                .scaleEffect(0.8)
                .offset(x: 4, y: 4)
            }

            // Title & date
            VStack(alignment: .leading, spacing: 2) {
                Text(document.displayTitle)
                    .font(MCTypography.captionBold)
                    .foregroundStyle(MCColors.textPrimary)
                    .lineLimit(2)

                Text(document.createdAt, style: .date)
                    .font(.system(size: 10))
                    .foregroundStyle(MCColors.textTertiary)

                if showEpisodeName, let episodeName = document.episode?.title {
                    Text(episodeName)
                        .font(.system(size: 10))
                        .foregroundStyle(MCColors.primaryTeal)
                        .lineLimit(1)
                }
            }
        }
        .padding(MCSpacing.xs)
        .background(MCColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadius))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
}
