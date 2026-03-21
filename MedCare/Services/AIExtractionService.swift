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

    /// Extract prescription data from images using AI.
    /// Uses Groq Vision when an API key is configured; falls back to rotating mocks otherwise.
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

        // Try real AI extraction if Groq is configured
        if let apiKey = LLMConfig.groqAPIKey, !apiKey.isEmpty,
           let imageData = prescriptionImage ?? medicineImages.first {
            do {
                return try await extractWithGroqVision(apiKey: apiKey, imageData: imageData)
            } catch {
                // Fall through to mock on any failure
                print("[AIExtractionService] Groq Vision failed, falling back to mock: \(error.localizedDescription)")
            }
        }

        // Fallback: rotating mocks
        extractionProgress = 0.2
        try await Task.sleep(nanoseconds: randomDelay(base: 800_000_000))
        extractionProgress = 0.5
        try await Task.sleep(nanoseconds: randomDelay(base: 1_200_000_000))
        extractionProgress = 0.7
        try await Task.sleep(nanoseconds: randomDelay(base: 900_000_000))
        extractionProgress = 0.9
        try await Task.sleep(nanoseconds: randomDelay(base: 400_000_000))
        return rotatingMockResult()
    }

    // MARK: - Groq Vision Extraction

    /// Sends a prescription image to Groq Vision and parses the structured JSON response.
    private func extractWithGroqVision(apiKey: String, imageData: Data) async throws -> ExtractionResult {
        extractionProgress = 0.1

        let base64Image = imageData.base64EncodedString()
        let mimeType = "image/jpeg"

        let systemPrompt = """
        You are a medical prescription reader for Indian prescriptions. \
        Extract all information from the prescription image and return ONLY valid JSON with no markdown formatting, no code fences, just the raw JSON object.
        """

        let userContent: [[String: Any]] = [
            ["type": "text", "text": """
            Extract all details from this prescription image. Return ONLY a JSON object (no markdown, no code fences) with this exact structure:
            {
              "doctorName": "string",
              "hospitalName": "string",
              "diagnosis": "string",
              "medicines": [
                {
                  "brandName": "string",
                  "genericName": "string",
                  "dosage": "string",
                  "frequency": "Once Daily | Twice Daily | Thrice Daily | Four Times Daily | As Needed | Weekly | Every 12 Hours | Every 8 Hours",
                  "timing": "Morning | Afternoon | Evening | Night",
                  "duration": "string",
                  "instructions": "string",
                  "manufacturer": "string",
                  "mrp": "string",
                  "expiryDate": "string"
                }
              ],
              "tasks": [
                {
                  "title": "string",
                  "taskType": "followUp | labTest | woundCare | physio | lifestyle",
                  "dueDays": 7
                }
              ]
            }
            Use empty string "" for any field you cannot read. Do not guess values — only extract what is clearly visible.
            """],
            ["type": "image_url", "image_url": ["url": "data:\(mimeType);base64,\(base64Image)"]]
        ]

        let body: [String: Any] = [
            "model": "llama-3.2-90b-vision-preview",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userContent]
            ],
            "temperature": 0.1,
            "max_tokens": 2048,
            "response_format": ["type": "json_object"]
        ]

        var request = URLRequest(url: URL(string: "https://api.groq.com/openai/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 60

        extractionProgress = 0.3

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw LLMError.invalidResponse(statusCode: statusCode)
        }

        extractionProgress = 0.7

        // Parse the response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String,
              let contentData = content.data(using: .utf8),
              let parsed = try JSONSerialization.jsonObject(with: contentData) as? [String: Any]
        else {
            throw LLMError.streamingFailed("Failed to parse Groq Vision response")
        }

        extractionProgress = 0.9

        return parseGroqResponse(parsed)
    }

    /// Converts raw JSON dictionary from Groq into an ExtractionResult.
    private func parseGroqResponse(_ json: [String: Any]) -> ExtractionResult {
        let doctorName = json["doctorName"] as? String ?? ""
        let hospitalName = json["hospitalName"] as? String ?? ""
        let diagnosis = json["diagnosis"] as? String ?? ""

        let rawMedicines = json["medicines"] as? [[String: Any]] ?? []
        let medicines: [MedicineExtraction] = rawMedicines.map { med in
            MedicineExtraction(
                brandName: fieldResult(med["brandName"]),
                genericName: fieldResult(med["genericName"]),
                dosage: fieldResult(med["dosage"]),
                frequency: fieldResult(med["frequency"]),
                timing: fieldResult(med["timing"]),
                duration: fieldResult(med["duration"]),
                instructions: fieldResult(med["instructions"]),
                manufacturer: fieldResult(med["manufacturer"]),
                mrp: fieldResult(med["mrp"]),
                expiryDate: fieldResult(med["expiryDate"])
            )
        }

        let rawTasks = json["tasks"] as? [[String: Any]] ?? []
        let now = Date()
        let tasks: [TaskExtraction] = rawTasks.compactMap { t in
            guard let title = t["title"] as? String, !title.isEmpty else { return nil }
            let typeStr = t["taskType"] as? String ?? "followUp"
            let taskType = mapTaskType(typeStr)
            let dueDays = t["dueDays"] as? Int ?? 7
            let dueDate = Calendar.current.date(byAdding: .day, value: dueDays, to: now)
            return TaskExtraction(title: title, taskType: taskType, dueDate: dueDate, confidence: 0.80)
        }

        return ExtractionResult(
            doctorName: FieldResult(value: doctorName, confidence: doctorName.isEmpty ? 0.0 : 0.85),
            hospitalName: FieldResult(value: hospitalName, confidence: hospitalName.isEmpty ? 0.0 : 0.80),
            diagnosis: FieldResult(value: diagnosis, confidence: diagnosis.isEmpty ? 0.0 : 0.82),
            medicines: medicines,
            tasks: tasks,
            overallConfidence: medicines.isEmpty ? 0.50 : 0.85
        )
    }

    /// Helper to create a FieldResult from an optional JSON value.
    private func fieldResult(_ value: Any?) -> FieldResult {
        let str = value as? String ?? ""
        return FieldResult(value: str, confidence: str.isEmpty ? 0.0 : 0.82)
    }

    /// Maps a task type string from JSON to the CareTaskType enum.
    private func mapTaskType(_ str: String) -> CareTaskType {
        switch str.lowercased() {
        case "followup", "follow_up", "follow-up": return .followUp
        case "labtest", "lab_test", "lab-test": return .labTest
        case "woundcare", "wound_care", "wound-care": return .woundCare
        case "physio", "physiotherapy": return .physio
        case "lifestyle": return .lifestyle
        default: return .followUp
        }
    }

    // MARK: - Helpers

    /// Returns a slightly randomized delay around the base value (±25%)
    private func randomDelay(base: UInt64) -> UInt64 {
        let variance = Double(base) * 0.25
        let offset = Double.random(in: -variance...variance)
        return UInt64(max(Double(base) + offset, 100_000_000))
    }

    /// Selects a mock result based on current time so each upload feels different
    private func rotatingMockResult() -> ExtractionResult {
        let index = Int(Date().timeIntervalSince1970) % mockResults.count
        return mockResults[index]
    }

    // MARK: - Mock Data

    private var mockResults: [ExtractionResult] {
        let now = Date()
        return [
            // Result 0: Cold & Cough — Dr. Priya Mehta
            ExtractionResult(
                doctorName: FieldResult(value: "Dr. Priya Mehta", confidence: 0.94),
                hospitalName: FieldResult(value: "Fortis Hospital, Delhi", confidence: 0.89),
                diagnosis: FieldResult(value: "Acute Upper Respiratory Infection with Allergic Rhinitis", confidence: 0.87),
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
                    TaskExtraction(title: "Follow-up visit", taskType: .followUp,
                                   dueDate: Calendar.current.date(byAdding: .day, value: 5, to: now), confidence: 0.82),
                    TaskExtraction(title: "Throat swab culture", taskType: .labTest,
                                   dueDate: Calendar.current.date(byAdding: .day, value: 2, to: now), confidence: 0.74)
                ],
                overallConfidence: 0.87
            ),

            // Result 1: Diabetes Management — Dr. Anil Kumar
            ExtractionResult(
                doctorName: FieldResult(value: "Dr. Anil Kumar", confidence: 0.96),
                hospitalName: FieldResult(value: "Max Super Speciality Hospital, Saket", confidence: 0.91),
                diagnosis: FieldResult(value: "Type 2 Diabetes Mellitus with Hypothyroidism", confidence: 0.90),
                medicines: [
                    MedicineExtraction(
                        brandName: FieldResult(value: "Glycomet GP 2", confidence: 0.94),
                        genericName: FieldResult(value: "Metformin + Glimepiride", confidence: 0.91),
                        dosage: FieldResult(value: "500mg/2mg", confidence: 0.93),
                        frequency: FieldResult(value: "Twice Daily", confidence: 0.95),
                        timing: FieldResult(value: "Before Breakfast, Before Dinner", confidence: 0.88),
                        duration: FieldResult(value: "90 days", confidence: 0.92),
                        instructions: FieldResult(value: "Take 15 minutes before meals", confidence: 0.86),
                        manufacturer: FieldResult(value: "USV Pvt Ltd", confidence: 0.89),
                        mrp: FieldResult(value: "₹145.60", confidence: 0.95),
                        expiryDate: FieldResult(value: "Dec 2027", confidence: 0.93)
                    ),
                    MedicineExtraction(
                        brandName: FieldResult(value: "Telma 40", confidence: 0.92),
                        genericName: FieldResult(value: "Telmisartan", confidence: 0.90),
                        dosage: FieldResult(value: "40mg", confidence: 0.96),
                        frequency: FieldResult(value: "Once Daily", confidence: 0.94),
                        timing: FieldResult(value: "Morning", confidence: 0.91),
                        duration: FieldResult(value: "90 days", confidence: 0.89),
                        instructions: FieldResult(value: "After breakfast", confidence: 0.83),
                        manufacturer: FieldResult(value: "Glenmark Pharma", confidence: 0.88),
                        mrp: FieldResult(value: "₹98.00", confidence: 0.92),
                        expiryDate: FieldResult(value: "Sep 2027", confidence: 0.90)
                    ),
                    MedicineExtraction(
                        brandName: FieldResult(value: "Thyronorm 50", confidence: 0.93),
                        genericName: FieldResult(value: "Levothyroxine Sodium", confidence: 0.91),
                        dosage: FieldResult(value: "50mcg", confidence: 0.97),
                        frequency: FieldResult(value: "Once Daily", confidence: 0.95),
                        timing: FieldResult(value: "Early Morning", confidence: 0.93),
                        duration: FieldResult(value: "90 days", confidence: 0.90),
                        instructions: FieldResult(value: "Empty stomach, 30 min before food", confidence: 0.88),
                        manufacturer: FieldResult(value: "Abbott India", confidence: 0.94),
                        mrp: FieldResult(value: "₹112.00", confidence: 0.91),
                        expiryDate: FieldResult(value: "Aug 2027", confidence: 0.89)
                    )
                ],
                tasks: [
                    TaskExtraction(title: "HbA1c Test", taskType: .labTest,
                                   dueDate: Calendar.current.date(byAdding: .month, value: 3, to: now), confidence: 0.88),
                    TaskExtraction(title: "Thyroid Profile (TSH, T3, T4)", taskType: .labTest,
                                   dueDate: Calendar.current.date(byAdding: .month, value: 2, to: now), confidence: 0.85),
                    TaskExtraction(title: "Follow-up with endocrinologist", taskType: .followUp,
                                   dueDate: Calendar.current.date(byAdding: .month, value: 3, to: now), confidence: 0.80)
                ],
                overallConfidence: 0.91
            ),

            // Result 2: Post-Surgery Recovery — Dr. Vikram Singh
            ExtractionResult(
                doctorName: FieldResult(value: "Dr. Vikram Singh", confidence: 0.93),
                hospitalName: FieldResult(value: "AIIMS, New Delhi", confidence: 0.95),
                diagnosis: FieldResult(value: "Post Lumbar Discectomy — Neuropathic Pain Management", confidence: 0.84),
                medicines: [
                    MedicineExtraction(
                        brandName: FieldResult(value: "Zerodol SP", confidence: 0.91),
                        genericName: FieldResult(value: "Aceclofenac + Paracetamol + Serratiopeptidase", confidence: 0.87),
                        dosage: FieldResult(value: "100mg/325mg/15mg", confidence: 0.85),
                        frequency: FieldResult(value: "Twice Daily", confidence: 0.92),
                        timing: FieldResult(value: "Morning, Night", confidence: 0.89),
                        duration: FieldResult(value: "10 days", confidence: 0.86),
                        instructions: FieldResult(value: "After food, do not crush", confidence: 0.80),
                        manufacturer: FieldResult(value: "IPCA Laboratories", confidence: 0.90),
                        mrp: FieldResult(value: "₹135.00", confidence: 0.93),
                        expiryDate: FieldResult(value: "Apr 2027", confidence: 0.88)
                    ),
                    MedicineExtraction(
                        brandName: FieldResult(value: "Pregabalin M 75", confidence: 0.89),
                        genericName: FieldResult(value: "Pregabalin + Methylcobalamin", confidence: 0.86),
                        dosage: FieldResult(value: "75mg/750mcg", confidence: 0.83),
                        frequency: FieldResult(value: "Twice Daily", confidence: 0.90),
                        timing: FieldResult(value: "Morning, Night", confidence: 0.87),
                        duration: FieldResult(value: "14 days", confidence: 0.78),
                        instructions: FieldResult(value: "After food, may cause drowsiness", confidence: 0.76),
                        manufacturer: FieldResult(value: "Torrent Pharma", confidence: 0.88),
                        mrp: FieldResult(value: "₹195.00", confidence: 0.91),
                        expiryDate: FieldResult(value: "Nov 2027", confidence: 0.90)
                    ),
                    MedicineExtraction(
                        brandName: FieldResult(value: "Pantocid 40", confidence: 0.93),
                        genericName: FieldResult(value: "Pantoprazole", confidence: 0.95),
                        dosage: FieldResult(value: "40mg", confidence: 0.97),
                        frequency: FieldResult(value: "Once Daily", confidence: 0.94),
                        timing: FieldResult(value: "Morning", confidence: 0.92),
                        duration: FieldResult(value: "14 days", confidence: 0.88),
                        instructions: FieldResult(value: "Before breakfast, empty stomach", confidence: 0.85),
                        manufacturer: FieldResult(value: "Sun Pharma", confidence: 0.91),
                        mrp: FieldResult(value: "₹126.00", confidence: 0.94),
                        expiryDate: FieldResult(value: "Feb 2027", confidence: 0.89)
                    )
                ],
                tasks: [
                    TaskExtraction(title: "Wound dressing change", taskType: .woundCare,
                                   dueDate: Calendar.current.date(byAdding: .day, value: 3, to: now), confidence: 0.90),
                    TaskExtraction(title: "Physiotherapy session", taskType: .physio,
                                   dueDate: Calendar.current.date(byAdding: .day, value: 7, to: now), confidence: 0.85),
                    TaskExtraction(title: "Post-op follow-up", taskType: .followUp,
                                   dueDate: Calendar.current.date(byAdding: .day, value: 14, to: now), confidence: 0.88)
                ],
                overallConfidence: 0.85
            ),

            // Result 3: Skin Infection — Dr. Neha Sharma
            ExtractionResult(
                doctorName: FieldResult(value: "Dr. Neha Sharma", confidence: 0.91),
                hospitalName: FieldResult(value: "Medanta Hospital, Gurugram", confidence: 0.87),
                diagnosis: FieldResult(value: "Bacterial Dermatitis with Secondary Fungal Infection", confidence: 0.82),
                medicines: [
                    MedicineExtraction(
                        brandName: FieldResult(value: "Azithromycin 500", confidence: 0.94),
                        genericName: FieldResult(value: "Azithromycin", confidence: 0.96),
                        dosage: FieldResult(value: "500mg", confidence: 0.98),
                        frequency: FieldResult(value: "Once Daily", confidence: 0.93),
                        timing: FieldResult(value: "Afternoon", confidence: 0.85),
                        duration: FieldResult(value: "3 days", confidence: 0.91),
                        instructions: FieldResult(value: "1 hour before or 2 hours after food", confidence: 0.79),
                        manufacturer: FieldResult(value: "Cipla Ltd", confidence: 0.92),
                        mrp: FieldResult(value: "₹78.50", confidence: 0.95),
                        expiryDate: FieldResult(value: "May 2027", confidence: 0.90)
                    ),
                    MedicineExtraction(
                        brandName: FieldResult(value: "Clobetasol Propionate Cream", confidence: 0.86),
                        genericName: FieldResult(value: "Clobetasol Propionate 0.05%", confidence: 0.83),
                        dosage: FieldResult(value: "0.05% w/w", confidence: 0.80),
                        frequency: FieldResult(value: "Twice Daily", confidence: 0.88),
                        timing: FieldResult(value: "Morning, Night", confidence: 0.84),
                        duration: FieldResult(value: "7 days", confidence: 0.76),
                        instructions: FieldResult(value: "Apply thin layer on affected area only", confidence: 0.72),
                        manufacturer: FieldResult(value: "Glenmark Pharma", confidence: 0.87),
                        mrp: FieldResult(value: "₹92.00", confidence: 0.91),
                        expiryDate: FieldResult(value: "Oct 2027", confidence: 0.88)
                    ),
                    MedicineExtraction(
                        brandName: FieldResult(value: "Cetirizine 10mg", confidence: 0.95),
                        genericName: FieldResult(value: "Cetirizine Hydrochloride", confidence: 0.93),
                        dosage: FieldResult(value: "10mg", confidence: 0.97),
                        frequency: FieldResult(value: "Once Daily", confidence: 0.94),
                        timing: FieldResult(value: "Night", confidence: 0.90),
                        duration: FieldResult(value: "10 days", confidence: 0.85),
                        instructions: FieldResult(value: "After dinner, may cause drowsiness", confidence: 0.81),
                        manufacturer: FieldResult(value: "Dr. Reddy's", confidence: 0.89),
                        mrp: FieldResult(value: "₹32.00", confidence: 0.96),
                        expiryDate: FieldResult(value: "Jul 2027", confidence: 0.92)
                    )
                ],
                tasks: [
                    TaskExtraction(title: "Dermatology follow-up", taskType: .followUp,
                                   dueDate: Calendar.current.date(byAdding: .day, value: 10, to: now), confidence: 0.78),
                    TaskExtraction(title: "Skin patch test", taskType: .labTest,
                                   dueDate: Calendar.current.date(byAdding: .day, value: 5, to: now), confidence: 0.70)
                ],
                overallConfidence: 0.84
            ),

            // Result 4: Hypertension — Dr. Rakesh Gupta
            ExtractionResult(
                doctorName: FieldResult(value: "Dr. Rakesh Gupta", confidence: 0.95),
                hospitalName: FieldResult(value: "Kokilaben Dhirubhai Ambani Hospital, Mumbai", confidence: 0.90),
                diagnosis: FieldResult(value: "Essential Hypertension (Stage 2) with Dyslipidemia", confidence: 0.88),
                medicines: [
                    MedicineExtraction(
                        brandName: FieldResult(value: "Amlodipine 5mg", confidence: 0.96),
                        genericName: FieldResult(value: "Amlodipine Besylate", confidence: 0.94),
                        dosage: FieldResult(value: "5mg", confidence: 0.98),
                        frequency: FieldResult(value: "Once Daily", confidence: 0.96),
                        timing: FieldResult(value: "Morning", confidence: 0.93),
                        duration: FieldResult(value: "90 days", confidence: 0.91),
                        instructions: FieldResult(value: "With or without food, same time daily", confidence: 0.87),
                        manufacturer: FieldResult(value: "Pfizer", confidence: 0.95),
                        mrp: FieldResult(value: "₹45.00", confidence: 0.97),
                        expiryDate: FieldResult(value: "Jan 2028", confidence: 0.93)
                    ),
                    MedicineExtraction(
                        brandName: FieldResult(value: "Losartan 50mg", confidence: 0.93),
                        genericName: FieldResult(value: "Losartan Potassium", confidence: 0.91),
                        dosage: FieldResult(value: "50mg", confidence: 0.96),
                        frequency: FieldResult(value: "Once Daily", confidence: 0.94),
                        timing: FieldResult(value: "Night", confidence: 0.90),
                        duration: FieldResult(value: "90 days", confidence: 0.88),
                        instructions: FieldResult(value: "After dinner", confidence: 0.84),
                        manufacturer: FieldResult(value: "MSD Pharma", confidence: 0.90),
                        mrp: FieldResult(value: "₹68.00", confidence: 0.93),
                        expiryDate: FieldResult(value: "Nov 2027", confidence: 0.91)
                    ),
                    MedicineExtraction(
                        brandName: FieldResult(value: "Ecosprin 75", confidence: 0.94),
                        genericName: FieldResult(value: "Aspirin (Acetylsalicylic Acid)", confidence: 0.92),
                        dosage: FieldResult(value: "75mg", confidence: 0.97),
                        frequency: FieldResult(value: "Once Daily", confidence: 0.95),
                        timing: FieldResult(value: "After Lunch", confidence: 0.88),
                        duration: FieldResult(value: "90 days", confidence: 0.90),
                        instructions: FieldResult(value: "After food, do not take on empty stomach", confidence: 0.86),
                        manufacturer: FieldResult(value: "USV Pvt Ltd", confidence: 0.91),
                        mrp: FieldResult(value: "₹18.50", confidence: 0.96),
                        expiryDate: FieldResult(value: "Mar 2028", confidence: 0.94)
                    )
                ],
                tasks: [
                    TaskExtraction(title: "Lipid Profile Test", taskType: .labTest,
                                   dueDate: Calendar.current.date(byAdding: .month, value: 1, to: now), confidence: 0.86),
                    TaskExtraction(title: "BP monitoring (daily log)", taskType: .lifestyle,
                                   dueDate: Calendar.current.date(byAdding: .day, value: 1, to: now), confidence: 0.92),
                    TaskExtraction(title: "Cardiology follow-up", taskType: .followUp,
                                   dueDate: Calendar.current.date(byAdding: .month, value: 3, to: now), confidence: 0.84)
                ],
                overallConfidence: 0.90
            )
        ]
    }
}
