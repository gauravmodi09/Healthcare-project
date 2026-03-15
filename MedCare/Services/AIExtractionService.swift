import Foundation
import SwiftUI

/// Handles AI-powered prescription extraction via GPT-4V
@Observable
final class AIExtractionService {
    var isExtracting = false
    var extractionProgress: Double = 0

    struct ExtractionResult {
        var doctorName: FieldResult
        var hospitalName: FieldResult
        var diagnosis: FieldResult
        var medicines: [MedicineExtraction]
        var tasks: [TaskExtraction]
        var overallConfidence: Double
    }

    struct FieldResult {
        var value: String
        var confidence: Double

        var isLowConfidence: Bool { confidence < 0.70 }
    }

    struct MedicineExtraction: Identifiable {
        let id = UUID()
        var brandName: FieldResult
        var genericName: FieldResult
        var dosage: FieldResult
        var frequency: FieldResult
        var timing: FieldResult
        var duration: FieldResult
        var instructions: FieldResult
        var manufacturer: FieldResult
        var mrp: FieldResult
        var expiryDate: FieldResult

        var overallConfidence: Double {
            let fields = [brandName, genericName, dosage, frequency, timing, duration]
            return fields.map(\.confidence).reduce(0, +) / Double(fields.count)
        }

        var hasLowConfidenceField: Bool {
            [brandName, genericName, dosage, frequency, timing, duration]
                .contains { $0.isLowConfidence }
        }
    }

    struct TaskExtraction: Identifiable {
        let id = UUID()
        var title: String
        var taskType: CareTaskType
        var dueDate: Date?
        var confidence: Double
    }

    /// Extract prescription data from images using AI
    func extractFromImages(
        prescriptionImage: Data?,
        medicineImages: [Data]
    ) async throws -> ExtractionResult {
        isExtracting = true
        extractionProgress = 0
        defer {
            isExtracting = false
            extractionProgress = 1.0
        }

        // Step 1: Upload images (simulated)
        extractionProgress = 0.2
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Step 2: GPT-4V extraction (simulated)
        extractionProgress = 0.5
        try await Task.sleep(nanoseconds: 1_500_000_000)

        // Step 3: Cross-reference prescription + packaging (simulated)
        extractionProgress = 0.7
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Step 4: Stitch MCP validation (simulated)
        extractionProgress = 0.9
        try await Task.sleep(nanoseconds: 500_000_000)

        // Return mock extraction result
        return mockExtractionResult()
    }

    private func mockExtractionResult() -> ExtractionResult {
        ExtractionResult(
            doctorName: FieldResult(value: "Dr. Rajesh Sharma", confidence: 0.92),
            hospitalName: FieldResult(value: "Apollo Hospital, Mumbai", confidence: 0.88),
            diagnosis: FieldResult(value: "Upper Respiratory Tract Infection", confidence: 0.85),
            medicines: [
                MedicineExtraction(
                    brandName: FieldResult(value: "Augmentin 625 Duo", confidence: 0.95),
                    genericName: FieldResult(value: "Amoxicillin + Clavulanic Acid", confidence: 0.93),
                    dosage: FieldResult(value: "625mg", confidence: 0.97),
                    frequency: FieldResult(value: "Twice Daily", confidence: 0.90),
                    timing: FieldResult(value: "Morning, Night", confidence: 0.88),
                    duration: FieldResult(value: "5 days", confidence: 0.85),
                    instructions: FieldResult(value: "After food", confidence: 0.82),
                    manufacturer: FieldResult(value: "GlaxoSmithKline", confidence: 0.96),
                    mrp: FieldResult(value: "₹228.50", confidence: 0.94),
                    expiryDate: FieldResult(value: "Mar 2027", confidence: 0.91)
                ),
                MedicineExtraction(
                    brandName: FieldResult(value: "Pan 40", confidence: 0.91),
                    genericName: FieldResult(value: "Pantoprazole", confidence: 0.89),
                    dosage: FieldResult(value: "40mg", confidence: 0.95),
                    frequency: FieldResult(value: "Once Daily", confidence: 0.87),
                    timing: FieldResult(value: "Morning", confidence: 0.92),
                    duration: FieldResult(value: "5 days", confidence: 0.83),
                    instructions: FieldResult(value: "Before food, empty stomach", confidence: 0.78),
                    manufacturer: FieldResult(value: "Alkem Laboratories", confidence: 0.90),
                    mrp: FieldResult(value: "₹115.00", confidence: 0.93),
                    expiryDate: FieldResult(value: "Jan 2027", confidence: 0.88)
                ),
                MedicineExtraction(
                    brandName: FieldResult(value: "Montek LC", confidence: 0.88),
                    genericName: FieldResult(value: "Montelukast + Levocetirizine", confidence: 0.65),
                    dosage: FieldResult(value: "10mg", confidence: 0.72),
                    frequency: FieldResult(value: "Once Daily", confidence: 0.91),
                    timing: FieldResult(value: "Night", confidence: 0.85),
                    duration: FieldResult(value: "7 days", confidence: 0.60),
                    instructions: FieldResult(value: "After dinner", confidence: 0.75),
                    manufacturer: FieldResult(value: "Sun Pharma", confidence: 0.92),
                    mrp: FieldResult(value: "₹165.00", confidence: 0.88),
                    expiryDate: FieldResult(value: "Jun 2027", confidence: 0.90)
                )
            ],
            tasks: [
                TaskExtraction(
                    title: "Follow-up visit",
                    taskType: .followUp,
                    dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
                    confidence: 0.80
                ),
                TaskExtraction(
                    title: "Complete Blood Count (CBC)",
                    taskType: .labTest,
                    dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
                    confidence: 0.75
                )
            ],
            overallConfidence: 0.86
        )
    }
}
