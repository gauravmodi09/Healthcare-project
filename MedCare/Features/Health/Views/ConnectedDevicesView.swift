import SwiftUI

// MARK: - Connected Devices View

struct ConnectedDevicesView: View {
    @State private var wearableService = WearableService()
    @State private var connectingSource: WearableSource?
    @State private var showError = false
    @State private var errorMessage = ""

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MCSpacing.lg) {
                    // Header info
                    headerCard

                    // Connected devices
                    if !wearableService.connectedDevices.isEmpty {
                        connectedSection
                    }

                    // Available to connect
                    availableSection
                }
                .padding(.vertical, MCSpacing.md)
            }
            .background(MCColors.backgroundLight)
            .navigationTitle("Connected Devices")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(MCColors.primaryTeal)
                }
            }
            .alert("Connection Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        MCCard {
            HStack(spacing: MCSpacing.sm) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 28))
                    .foregroundStyle(MCColors.primaryTeal)

                VStack(alignment: .leading, spacing: MCSpacing.xxs) {
                    Text("Wearable Devices")
                        .font(MCTypography.headline)
                        .foregroundStyle(MCColors.textPrimary)

                    Text("Connect your health devices to sync vitals automatically")
                        .font(MCTypography.caption)
                        .foregroundStyle(MCColors.textSecondary)
                }

                Spacer()
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Connected Section

    private var connectedSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            Text("CONNECTED")
                .font(MCTypography.sectionHeader)
                .foregroundStyle(MCColors.textTertiary)
                .textCase(.uppercase)
                .kerning(1.2)
                .padding(.horizontal, MCSpacing.screenPadding)

            ForEach(sortedConnectedDevices) { device in
                connectedDeviceRow(device)
            }
        }
    }

    private func connectedDeviceRow(_ device: WearableDevice) -> some View {
        MCCard {
            HStack(spacing: MCSpacing.sm) {
                // Icon
                Image(systemName: device.source.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(Color(hex: device.source.brandColor))
                    .frame(width: 44, height: 44)
                    .background(Color(hex: device.source.brandColor).opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))

                VStack(alignment: .leading, spacing: 2) {
                    Text(device.name)
                        .font(MCTypography.bodyMedium)
                        .foregroundStyle(MCColors.textPrimary)

                    HStack(spacing: MCSpacing.xxs) {
                        Circle()
                            .fill(MCColors.success)
                            .frame(width: 6, height: 6)

                        Text(device.lastSyncDisplay)
                            .font(MCTypography.caption)
                            .foregroundStyle(MCColors.textSecondary)
                    }

                    // Supported vitals
                    Text(device.supportedVitals.prefix(4).map(\.rawValue).joined(separator: " \u{2022} "))
                        .font(.system(size: 10))
                        .foregroundStyle(MCColors.textTertiary)
                        .lineLimit(1)
                }

                Spacer()

                VStack(spacing: MCSpacing.xxs) {
                    // Sync button
                    Button {
                        Task { await wearableService.syncData(from: device.source) }
                    } label: {
                        if wearableService.isSyncing {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(MCColors.primaryTeal)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(width: MCSpacing.touchTarget, height: 28)

                    // Disconnect (not for Apple Watch)
                    if device.source != .appleWatch {
                        Button {
                            wearableService.disconnectDevice(source: device.source)
                        } label: {
                            Text("Remove")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(MCColors.error)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Available Section

    private var availableSection: some View {
        VStack(alignment: .leading, spacing: MCSpacing.sm) {
            Text("AVAILABLE")
                .font(MCTypography.sectionHeader)
                .foregroundStyle(MCColors.textTertiary)
                .textCase(.uppercase)
                .kerning(1.2)
                .padding(.horizontal, MCSpacing.screenPadding)

            ForEach(unconnectedSources) { source in
                availableDeviceRow(source)
            }
        }
    }

    private func availableDeviceRow(_ source: WearableSource) -> some View {
        MCCard {
            HStack(spacing: MCSpacing.sm) {
                // Icon
                Image(systemName: source.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(Color(hex: source.brandColor))
                    .frame(width: 44, height: 44)
                    .background(Color(hex: source.brandColor).opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: MCSpacing.cornerRadiusSmall))

                VStack(alignment: .leading, spacing: 2) {
                    Text(source.rawValue)
                        .font(MCTypography.bodyMedium)
                        .foregroundStyle(MCColors.textPrimary)

                    Text(source.supportedVitals.prefix(4).map(\.rawValue).joined(separator: " \u{2022} "))
                        .font(.system(size: 10))
                        .foregroundStyle(MCColors.textTertiary)
                        .lineLimit(1)

                    if source.connectionMethod == .terraAPI {
                        Text("Via Terra API")
                            .font(.system(size: 9))
                            .foregroundStyle(MCColors.textTertiary)
                    }
                }

                Spacer()

                Button {
                    connectDevice(source)
                } label: {
                    if connectingSource == source {
                        ProgressView()
                            .controlSize(.small)
                            .frame(width: 80, height: 32)
                    } else {
                        Text("Connect")
                            .font(MCTypography.captionBold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, MCSpacing.md)
                            .padding(.vertical, MCSpacing.xs)
                            .background(MCColors.primaryTeal)
                            .clipShape(Capsule())
                    }
                }
                .buttonStyle(.plain)
                .disabled(connectingSource != nil)
            }
        }
        .padding(.horizontal, MCSpacing.screenPadding)
    }

    // MARK: - Actions

    private func connectDevice(_ source: WearableSource) {
        connectingSource = source
        Task {
            do {
                try await wearableService.connectDevice(source: source)
            } catch {
                errorMessage = "Failed to connect \(source.rawValue): \(error.localizedDescription)"
                showError = true
            }
            connectingSource = nil
        }
    }

    // MARK: - Computed

    private var sortedConnectedDevices: [WearableDevice] {
        // Apple Watch first, then alphabetical
        wearableService.connectedDevices.sorted { a, b in
            if a.source == .appleWatch { return true }
            if b.source == .appleWatch { return false }
            return a.name < b.name
        }
    }

    private var unconnectedSources: [WearableSource] {
        let connectedSourceSet = Set(wearableService.connectedDevices.map(\.source))
        return WearableSource.allCases.filter {
            !connectedSourceSet.contains($0) && $0 != .manual
        }
    }
}
