import SwiftUI

struct HealthRecordImportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var providerQuery = ""
    @State private var searchResults: [ABDMService.HealthProvider] = []
    @State private var selectedProvider: ABDMService.HealthProvider?
    @State private var selectedDataTypes: Set<ABDMService.HealthDataType> = []
    @State private var dateFrom = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    @State private var dateTo = Date()
    @State private var consentRequests: [ABDMService.ConsentRequest] = []
    @State private var importedRecords: [ABDMService.ImportedHealthRecord] = []
    @State private var isSearching = false
    @State private var isRequesting = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var selectedRecord: ABDMService.ImportedHealthRecord?
    @State private var showRecordDetail = false

    private let abdmService = ABDMService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    requestSection
                    if !consentRequests.isEmpty {
                        pendingRequestsSection
                    }
                    if !importedRecords.isEmpty {
                        importedRecordsSection
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Import Health Records")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
            .sheet(isPresented: $showRecordDetail) {
                if let record = selectedRecord {
                    HealthRecordDetailView(record: record)
                }
            }
            .onAppear {
                loadSavedData()
            }
        }
    }

    // MARK: - Request Section

    private var requestSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Text("Request Records")
                .font(.headline)
                .padding(.horizontal, 16)

            VStack(spacing: 0) {
                // Provider search
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hospital / Provider")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search hospitals, clinics, labs...", text: $providerQuery)
                            .textFieldStyle(.plain)
                            .autocorrectionDisabled()
                            .onSubmit { searchProviders() }

                        if isSearching {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    if let provider = selectedProvider {
                        HStack(spacing: 8) {
                            Image(systemName: "building.2.fill")
                                .foregroundStyle(.teal)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(provider.name)
                                    .font(.subheadline.weight(.medium))
                                Text("\(provider.city) \u{00B7} \(provider.type)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                selectedProvider = nil
                                providerQuery = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(10)
                        .background(Color.teal.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Search results dropdown
                    if !searchResults.isEmpty && selectedProvider == nil {
                        VStack(spacing: 0) {
                            ForEach(searchResults) { provider in
                                Button {
                                    selectedProvider = provider
                                    providerQuery = provider.name
                                    searchResults = []
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(provider.name)
                                                .font(.subheadline)
                                                .foregroundStyle(.primary)
                                            Text("\(provider.city) \u{00B7} \(provider.type)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                }
                                if provider.id != searchResults.last?.id {
                                    Divider().padding(.leading, 12)
                                }
                            }
                        }
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                    }
                }
                .padding(16)

                Divider().padding(.leading, 16)

                // Data types selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Data Types")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(ABDMService.HealthDataType.allCases) { dataType in
                            dataTypeToggle(dataType)
                        }
                    }
                }
                .padding(16)

                Divider().padding(.leading, 16)

                // Date range
                VStack(alignment: .leading, spacing: 10) {
                    Text("Date Range")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("From")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            DatePicker("", selection: $dateFrom, displayedComponents: .date)
                                .labelsHidden()
                        }

                        Image(systemName: "arrow.right")
                            .foregroundStyle(.tertiary)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("To")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            DatePicker("", selection: $dateTo, displayedComponents: .date)
                                .labelsHidden()
                        }
                    }
                }
                .padding(16)

                Divider().padding(.leading, 16)

                // Request button
                Button {
                    requestRecords()
                } label: {
                    HStack(spacing: 8) {
                        if isRequesting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.down.doc.fill")
                        }
                        Text("Request Records")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(canRequest ? Color.teal : Color.gray.opacity(0.3))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!canRequest || isRequesting)
                .padding(16)
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
        }
    }

    private func dataTypeToggle(_ dataType: ABDMService.HealthDataType) -> some View {
        let isSelected = selectedDataTypes.contains(dataType)
        return Button {
            if isSelected {
                selectedDataTypes.remove(dataType)
            } else {
                selectedDataTypes.insert(dataType)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: dataType.icon)
                    .font(.system(size: 14))
                Text(dataType.displayName)
                    .font(.subheadline)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .teal : .secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? Color.teal.opacity(0.08) : Color(.systemGray6))
            .foregroundStyle(isSelected ? .teal : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    // MARK: - Pending Requests

    private var pendingRequestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pending Requests")
                .font(.headline)
                .padding(.horizontal, 16)

            VStack(spacing: 0) {
                ForEach(consentRequests) { request in
                    consentRequestRow(request)
                    if request.id != consentRequests.last?.id {
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
        }
    }

    private func consentRequestRow(_ request: ABDMService.ConsentRequest) -> some View {
        HStack(spacing: 12) {
            statusIcon(for: request.status)

            VStack(alignment: .leading, spacing: 4) {
                Text(request.providerName)
                    .font(.subheadline.weight(.medium))
                Text(request.dataTypes.map(\.displayName).joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(request.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            statusBadge(for: request.status)
        }
        .padding(14)
        .contentShape(Rectangle())
        .onTapGesture {
            if request.status == .approved, let artifactId = request.consentArtifactId {
                fetchRecords(artifactId: artifactId, providerName: request.providerName)
            } else if request.status == .requested {
                pollConsentStatus(request)
            }
        }
    }

    private func statusIcon(for status: ABDMService.ConsentRequestStatus) -> some View {
        let (icon, color): (String, Color) = {
            switch status {
            case .requested: return ("clock.fill", .orange)
            case .approved: return ("checkmark.circle.fill", .green)
            case .denied: return ("xmark.circle.fill", .red)
            case .expired: return ("clock.badge.exclamationmark.fill", .gray)
            }
        }()

        return Image(systemName: icon)
            .font(.system(size: 24))
            .foregroundStyle(color)
            .frame(width: 32)
    }

    private func statusBadge(for status: ABDMService.ConsentRequestStatus) -> some View {
        let color: Color = {
            switch status {
            case .requested: return .orange
            case .approved: return .green
            case .denied: return .red
            case .expired: return .gray
            }
        }()

        return Text(status.displayName)
            .font(.caption.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    // MARK: - Imported Records

    private var importedRecordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Imported Records")
                .font(.headline)
                .padding(.horizontal, 16)

            VStack(spacing: 0) {
                ForEach(importedRecords) { record in
                    Button {
                        selectedRecord = record
                        showRecordDetail = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: record.dataType.icon)
                                .font(.system(size: 20))
                                .foregroundStyle(.teal)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.title)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.primary)
                                Text(record.providerName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(record.recordDate, style: .date)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(14)
                    }

                    if record.id != importedRecords.last?.id {
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Helpers

    private var canRequest: Bool {
        selectedProvider != nil && !selectedDataTypes.isEmpty
    }

    private func loadSavedData() {
        consentRequests = abdmService.savedConsentRequests()
        importedRecords = abdmService.savedImportedRecords()
    }

    private func searchProviders() {
        guard !providerQuery.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSearching = true
        Task {
            do {
                let results = try await abdmService.searchProviders(query: providerQuery)
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    isSearching = false
                    // Show empty results on error — user can retry
                    searchResults = []
                }
            }
        }
    }

    private func requestRecords() {
        guard let provider = selectedProvider else { return }
        isRequesting = true
        Task {
            do {
                let response = try await abdmService.requestConsent(
                    fromProvider: provider.id,
                    forDataTypes: Array(selectedDataTypes),
                    dateRange: dateFrom...dateTo
                )
                let consentRequest = ABDMService.ConsentRequest(
                    id: UUID().uuidString,
                    requestId: response.requestId,
                    providerName: provider.name,
                    dataTypes: Array(selectedDataTypes),
                    dateRangeStart: dateFrom,
                    dateRangeEnd: dateTo,
                    status: ABDMService.ConsentRequestStatus(rawValue: response.status) ?? .requested,
                    createdAt: Date(),
                    consentArtifactId: nil
                )
                abdmService.saveConsentRequest(consentRequest)
                await MainActor.run {
                    isRequesting = false
                    selectedProvider = nil
                    providerQuery = ""
                    selectedDataTypes = []
                    loadSavedData()
                }
            } catch {
                await MainActor.run {
                    isRequesting = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    private func pollConsentStatus(_ request: ABDMService.ConsentRequest) {
        Task {
            do {
                let status = try await abdmService.checkConsentStatus(requestId: request.requestId)
                let updatedRequest = ABDMService.ConsentRequest(
                    id: request.id,
                    requestId: request.requestId,
                    providerName: request.providerName,
                    dataTypes: request.dataTypes,
                    dateRangeStart: request.dateRangeStart,
                    dateRangeEnd: request.dateRangeEnd,
                    status: ABDMService.ConsentRequestStatus(rawValue: status.status) ?? request.status,
                    createdAt: request.createdAt,
                    consentArtifactId: status.consentArtifactId
                )
                abdmService.saveConsentRequest(updatedRequest)
                await MainActor.run { loadSavedData() }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    private func fetchRecords(artifactId: String, providerName: String) {
        Task {
            do {
                var records = try await abdmService.fetchHealthRecords(consentArtifactId: artifactId)
                records = records.map { record in
                    ABDMService.ImportedHealthRecord(
                        id: record.id,
                        providerName: providerName,
                        dataType: record.dataType,
                        recordDate: record.recordDate,
                        importedAt: record.importedAt,
                        title: record.title,
                        summary: record.summary,
                        fhirResourceType: record.fhirResourceType,
                        rawData: record.rawData
                    )
                }
                abdmService.saveImportedRecords(records)
                await MainActor.run { loadSavedData() }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Health Record Detail View

struct HealthRecordDetailView: View {
    let record: ABDMService.ImportedHealthRecord
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack(spacing: 12) {
                        Image(systemName: record.dataType.icon)
                            .font(.system(size: 28))
                            .foregroundStyle(.teal)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.title)
                                .font(.title3.weight(.semibold))
                            Text(record.providerName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Details
                    VStack(alignment: .leading, spacing: 12) {
                        detailRow("Record Type", value: record.dataType.displayName)
                        detailRow("Date", value: record.recordDate.formatted(date: .long, time: .omitted))
                        detailRow("Imported", value: record.importedAt.formatted(date: .abbreviated, time: .shortened))
                        detailRow("FHIR Resource", value: record.fhirResourceType)

                        Divider()

                        Text("Summary")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                        Text(record.summary)
                            .font(.body)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Record Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func detailRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
        }
    }
}

#Preview {
    HealthRecordImportView()
}
