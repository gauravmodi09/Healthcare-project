import Foundation

// MARK: - Drug Answer Model

struct DrugAnswer: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
    let sources: [String]
    let relatedQuestions: [String]
}

// MARK: - Drug Q&A Service

@Observable
final class DrugQAService {

    private let drugDB = IndianDrugDatabase.shared
    private let interactionService = DrugInteractionService()

    // MARK: - Public API

    /// Answers a natural-language drug question using the on-device Indian Drug Database.
    func answerQuery(medicine: String, question: String) -> DrugAnswer {
        let lower = question.lowercased()
        let entries = drugDB.searchMedicines(query: medicine)
        guard let entry = entries.first else {
            return DrugAnswer(
                question: question,
                answer: "Sorry, I couldn't find \"\(medicine)\" in the database. Please check the spelling or try the generic name.",
                sources: [],
                relatedQuestions: [
                    "What is the generic name for \(medicine)?",
                    "Is \(medicine) available in India?"
                ]
            )
        }

        // Route to appropriate handler
        if containsAny(lower, ["side effect", "reaction", "adverse", "nuksan", "problem"]) {
            return sideEffectsAnswer(entry: entry, question: question)
        }

        if containsAny(lower, ["food", "eat", "drink", "khana", "meal", "alcohol", "juice", "milk"]) {
            return foodInteractionsAnswer(entry: entry, question: question)
        }

        if containsAny(lower, ["generic", "alternative", "cheaper", "substitute", "sasta", "brand"]) {
            return genericAlternativesAnswer(entry: entry, question: question)
        }

        if containsAny(lower, ["dosage", "dose", "how to take", "how should", "kaise le", "kitni"]) {
            return dosageAnswer(entry: entry, question: question)
        }

        if containsAny(lower, ["store", "storage", "keep", "rakhna", "preserve", "fridge", "temperature"]) {
            return storageAnswer(entry: entry, question: question)
        }

        if containsAny(lower, ["interact", "combine", "together", "mix", "saath"]) {
            return interactionsAnswer(entry: entry, question: question)
        }

        // General info fallback
        return generalInfoAnswer(entry: entry, question: question)
    }

    // MARK: - Side Effects

    private func sideEffectsAnswer(entry: DrugEntry, question: String) -> DrugAnswer {
        let effects = entry.commonSideEffects
        var answer: String

        if effects.isEmpty {
            answer = "No common side effects are listed for \(entry.brandName) (\(entry.genericName)) in our database."
        } else {
            answer = "Common side effects of \(entry.brandName) (\(entry.genericName)):\n\n"
            for effect in effects {
                answer += "  \u{2022} \(effect)\n"
            }
            answer += "\nMost side effects are mild and may resolve on their own. Consult your doctor if any side effect persists or worsens."
        }

        return DrugAnswer(
            question: question,
            answer: answer,
            sources: ["Indian Drug Database", "Manufacturer: \(entry.manufacturer)"],
            relatedQuestions: [
                "What are the food interactions for \(entry.brandName)?",
                "Are there cheaper alternatives to \(entry.brandName)?",
                "How should I take \(entry.brandName)?"
            ]
        )
    }

    // MARK: - Food Interactions

    private func foodInteractionsAnswer(entry: DrugEntry, question: String) -> DrugAnswer {
        let interactions = entry.foodInteractions
        var answer: String

        if interactions.isEmpty {
            answer = "No specific food interactions are listed for \(entry.brandName) (\(entry.genericName)). It is generally safe to take with or without food, but follow your doctor's advice."
        } else {
            answer = "Food interactions for \(entry.brandName) (\(entry.genericName)):\n\n"
            for interaction in interactions {
                answer += "  \u{2022} \(interaction)\n"
            }
            answer += "\nAlways follow your doctor's instructions about when to take this medicine relative to meals."
        }

        return DrugAnswer(
            question: question,
            answer: answer,
            sources: ["Indian Drug Database", "Manufacturer: \(entry.manufacturer)"],
            relatedQuestions: [
                "What are the side effects of \(entry.brandName)?",
                "How should I store \(entry.brandName)?",
                "Can I take \(entry.brandName) with other medicines?"
            ]
        )
    }

    // MARK: - Generic Alternatives

    private func genericAlternativesAnswer(entry: DrugEntry, question: String) -> DrugAnswer {
        let alternatives = entry.genericAlternatives
        var answer: String

        answer = "\(entry.brandName) contains \(entry.genericName) (\(entry.saltComposition)).\n"
        answer += "Price range: \(entry.priceRange)\n\n"

        if alternatives.isEmpty {
            answer += "No generic alternatives are listed in our database. Ask your pharmacist about generic versions of \(entry.genericName)."
        } else {
            answer += "Available alternatives:\n\n"
            for alt in alternatives {
                answer += "  \u{2022} \(alt.brandName) by \(alt.manufacturer) — \(alt.priceRange)\n"
            }
            answer += "\nNote: Always consult your doctor before switching to a different brand."
        }

        return DrugAnswer(
            question: question,
            answer: answer,
            sources: ["Indian Drug Database"],
            relatedQuestions: [
                "What are the side effects of \(entry.genericName)?",
                "Is \(entry.brandName) a Schedule H drug?",
                "How should I take \(entry.brandName)?"
            ]
        )
    }

    // MARK: - Dosage Info

    private func dosageAnswer(entry: DrugEntry, question: String) -> DrugAnswer {
        let dosages = entry.commonDosages
        var answer: String

        answer = "\(entry.brandName) (\(entry.genericName))\n"
        answer += "Form: \(entry.typicalDoseForm)\n\n"

        if dosages.isEmpty {
            answer += "No standard dosage information is available. Please follow your doctor's prescription."
        } else {
            answer += "Common dosages:\n\n"
            for dosage in dosages {
                answer += "  \u{2022} \(dosage)\n"
            }
            answer += "\nAlways take as prescribed by your doctor. Do not change your dosage without medical advice."
        }

        if entry.isScheduleH {
            answer += "\n\u{26A0}\u{FE0F} This is a Schedule H drug — available only with a valid prescription."
        }

        return DrugAnswer(
            question: question,
            answer: answer,
            sources: ["Indian Drug Database", "Manufacturer: \(entry.manufacturer)"],
            relatedQuestions: [
                "What are the side effects of \(entry.brandName)?",
                "Can I take \(entry.brandName) with food?",
                "How should I store \(entry.brandName)?"
            ]
        )
    }

    // MARK: - Storage

    private func storageAnswer(entry: DrugEntry, question: String) -> DrugAnswer {
        let storage = entry.storageInstructions
        var answer: String

        if storage.isEmpty {
            answer = "No specific storage instructions are available for \(entry.brandName). General tips:\n\n"
            answer += "  \u{2022} Store in a cool, dry place\n"
            answer += "  \u{2022} Keep away from direct sunlight\n"
            answer += "  \u{2022} Keep out of reach of children\n"
            answer += "  \u{2022} Do not use after the expiry date"
        } else {
            answer = "Storage instructions for \(entry.brandName) (\(entry.genericName)):\n\n"
            answer += "  \u{2022} \(storage)\n"
            answer += "\nAlways check the expiry date before use."
        }

        return DrugAnswer(
            question: question,
            answer: answer,
            sources: ["Indian Drug Database", "Manufacturer: \(entry.manufacturer)"],
            relatedQuestions: [
                "What are the side effects of \(entry.brandName)?",
                "How should I take \(entry.brandName)?",
                "Are there alternatives to \(entry.brandName)?"
            ]
        )
    }

    // MARK: - Drug Interactions

    private func interactionsAnswer(entry: DrugEntry, question: String) -> DrugAnswer {
        // Try to extract a second medicine from the question
        let lower = question.lowercased()
        var secondMedicine: String?

        // Pattern: "interact with X", "combine with X", "take X with Y"
        let patterns = [
            #"(?:interact|combine|mix|take)\s+(?:\w+\s+)?with\s+(\w+)"#,
            #"(\w+)\s+(?:and|with)\s+\#(entry.brandName.lowercased())"#,
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(lower.startIndex..., in: lower)
                if let match = regex.firstMatch(in: lower, range: range),
                   let captureRange = Range(match.range(at: 1), in: lower) {
                    let candidate = String(lower[captureRange])
                    let results = drugDB.searchMedicines(query: candidate)
                    if !results.isEmpty {
                        secondMedicine = results.first?.brandName ?? candidate
                    } else {
                        secondMedicine = candidate
                    }
                    break
                }
            }
        }

        var answer: String

        if let secondMedicine {
            let alerts = interactionService.checkInteractions(medicines: [entry.genericName, secondMedicine])
            if alerts.isEmpty {
                answer = "No known interactions found between \(entry.brandName) (\(entry.genericName)) and \(secondMedicine) in our database.\n\n"
                answer += "However, always inform your doctor about all medicines you are taking."
            } else {
                answer = "Interactions between \(entry.brandName) and \(secondMedicine):\n\n"
                for alert in alerts {
                    answer += "  \u{2022} [\(alert.severity.rawValue)] \(alert.description)\n"
                    answer += "    Recommendation: \(alert.recommendation)\n\n"
                }
            }
        } else {
            answer = "To check drug interactions for \(entry.brandName) (\(entry.genericName)), please specify the other medicine.\n\n"
            answer += "Example: \"Does \(entry.brandName) interact with [other medicine]?\""
        }

        return DrugAnswer(
            question: question,
            answer: answer,
            sources: ["Drug Interaction Database"],
            relatedQuestions: [
                "What are the side effects of \(entry.brandName)?",
                "Can I take \(entry.brandName) with food?",
                "What is the generic for \(entry.brandName)?"
            ]
        )
    }

    // MARK: - General Info

    private func generalInfoAnswer(entry: DrugEntry, question: String) -> DrugAnswer {
        var answer = "\(entry.brandName)\n"
        answer += "Generic: \(entry.genericName)\n"
        answer += "Salt: \(entry.saltComposition)\n"
        answer += "Category: \(entry.category.rawValue)\n"
        answer += "Manufacturer: \(entry.manufacturer)\n"
        answer += "Form: \(entry.typicalDoseForm)\n"
        answer += "Price: \(entry.priceRange)\n"

        if entry.isScheduleH {
            answer += "Schedule H: Yes (prescription required)\n"
        }

        if !entry.description.isEmpty {
            answer += "\n\(entry.description)"
        }

        return DrugAnswer(
            question: question,
            answer: answer,
            sources: ["Indian Drug Database"],
            relatedQuestions: [
                "What are the side effects of \(entry.brandName)?",
                "Are there cheaper alternatives to \(entry.brandName)?",
                "What are the food interactions for \(entry.brandName)?",
                "How should I take \(entry.brandName)?"
            ]
        )
    }

    // MARK: - Helpers

    private func containsAny(_ text: String, _ keywords: [String]) -> Bool {
        keywords.contains(where: { text.contains($0) })
    }
}
