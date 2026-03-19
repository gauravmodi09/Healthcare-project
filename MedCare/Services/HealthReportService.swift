import UIKit
import SwiftUI

/// Generates professional PDF health reports for patients to share with doctors
final class HealthReportService {

    // MARK: - Constants

    private let pageWidth: CGFloat = 595   // A4
    private let pageHeight: CGFloat = 842  // A4
    private let margin: CGFloat = 40
    private let headerHeight: CGFloat = 90
    private let footerHeight: CGFloat = 40

    // Brand colors (teal from MCColors)
    private let tealColor = UIColor(red: 13/255, green: 148/255, blue: 136/255, alpha: 1)    // #0D9488
    private let tealLight = UIColor(red: 45/255, green: 212/255, blue: 191/255, alpha: 1)     // #2DD4BF
    private let darkText = UIColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 1)        // #0F172A
    private let secondaryText = UIColor(red: 100/255, green: 116/255, blue: 139/255, alpha: 1) // #64748B
    private let successGreen = UIColor(red: 34/255, green: 197/255, blue: 94/255, alpha: 1)   // #22C55E
    private let warningAmber = UIColor(red: 245/255, green: 158/255, blue: 11/255, alpha: 1)  // #F59E0B
    private let errorRed = UIColor(red: 239/255, green: 68/255, blue: 68/255, alpha: 1)       // #EF4444
    private let lightGray = UIColor(red: 241/255, green: 245/255, blue: 249/255, alpha: 1)    // #F1F5F9
    private let borderGray = UIColor(red: 226/255, green: 232/255, blue: 240/255, alpha: 1)   // #E2E8F0

    // Fonts
    private func font(_ size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        UIFont.systemFont(ofSize: size, weight: weight)
    }

    private func roundedFont(_ size: CGFloat, weight: UIFont.Weight = .bold) -> UIFont {
        let descriptor = UIFont.systemFont(ofSize: size, weight: weight).fontDescriptor
            .withDesign(.rounded)!
        return UIFont(descriptor: descriptor, size: size)
    }

    private var contentWidth: CGFloat { pageWidth - margin * 2 }

    // MARK: - Generate Report

    func generateReport(
        profile: UserProfile,
        medicines: [Medicine],
        doseLogs: [DoseLog],
        symptomLogs: [SymptomLog],
        episodes: [Episode],
        healthScore: HealthScore,
        dateRange: ClosedRange<Date>
    ) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        var pageNumber = 0

        // Filter data to date range
        let filteredDoseLogs = doseLogs.filter { dateRange.contains($0.scheduledTime) }
        let filteredSymptomLogs = symptomLogs.filter { dateRange.contains($0.date) }
        let activeEpisodes = episodes.filter { $0.status == .active || $0.status == .pendingConfirmation }
        let activeMedicines = medicines.filter { $0.isActive }

        // Calculate adherence stats
        let totalDoses = filteredDoseLogs.count
        let takenDoses = filteredDoseLogs.filter { $0.status == .taken }.count
        let missedDoses = filteredDoseLogs.filter { $0.status == .missed }.count
        let skippedDoses = filteredDoseLogs.filter { $0.status == .skipped }.count
        let adherencePercent = totalDoses > 0 ? Double(takenDoses) / Double(totalDoses) * 100 : 0

        let data = renderer.pdfData { context in
            // ── Page 1 ──
            pageNumber += 1
            context.beginPage()
            var y = drawHeader(context: context.cgContext, pageNumber: pageNumber)

            // Patient Info
            y = drawPatientInfo(context: context.cgContext, y: y, profile: profile, dateRange: dateRange)

            // Health Score
            y = drawHealthScore(context: context.cgContext, y: y, healthScore: healthScore)

            // Adherence Summary
            y = drawAdherenceSummary(
                context: context.cgContext, y: y,
                adherencePercent: adherencePercent,
                taken: takenDoses, missed: missedDoses, skipped: skippedDoses, total: totalDoses
            )

            // Adherence Calendar Heatmap
            y = drawAdherenceHeatmap(context: context.cgContext, y: y, doseLogs: filteredDoseLogs, dateRange: dateRange)

            drawFooter(context: context.cgContext, pageNumber: pageNumber)

            // ── Page 2 ──
            pageNumber += 1
            context.beginPage()
            y = drawHeader(context: context.cgContext, pageNumber: pageNumber)

            // Medications Table
            y = drawMedicationsTable(context: context.cgContext, y: y, medicines: activeMedicines)

            // Symptom Summary
            if !filteredSymptomLogs.isEmpty {
                y = drawSymptomSummary(context: context.cgContext, y: y, symptomLogs: filteredSymptomLogs)
            }

            // Active Episodes
            if !activeEpisodes.isEmpty {
                // Check if we need a new page
                if y > pageHeight - footerHeight - 200 {
                    drawFooter(context: context.cgContext, pageNumber: pageNumber)
                    pageNumber += 1
                    context.beginPage()
                    y = drawHeader(context: context.cgContext, pageNumber: pageNumber)
                }
                y = drawActiveEpisodes(context: context.cgContext, y: y, episodes: activeEpisodes)
            }

            // Key Insights
            if y > pageHeight - footerHeight - 120 {
                drawFooter(context: context.cgContext, pageNumber: pageNumber)
                pageNumber += 1
                context.beginPage()
                y = drawHeader(context: context.cgContext, pageNumber: pageNumber)
            }
            _ = drawInsights(context: context.cgContext, y: y, healthScore: healthScore)

            drawFooter(context: context.cgContext, pageNumber: pageNumber)
        }

        return data
    }

    // MARK: - Share Report

    func shareReport(data: Data) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let dateStr = Self.fileDateFormatter.string(from: Date())
        let fileURL = tempDir.appendingPathComponent("MedCare_Health_Report_\(dateStr).pdf")

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            return nil
        }
    }

    // MARK: - Drawing: Header

    private func drawHeader(context: CGContext, pageNumber: Int) -> CGFloat {
        // Teal header band
        context.setFillColor(tealColor.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: pageWidth, height: headerHeight))

        // App name
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: roundedFont(22, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        let title = NSAttributedString(string: "MedCare", attributes: titleAttrs)
        title.draw(at: CGPoint(x: margin, y: 20))

        // Subtitle
        let subtitleAttrs: [NSAttributedString.Key: Any] = [
            .font: font(12, weight: .medium),
            .foregroundColor: UIColor.white.withAlphaComponent(0.85)
        ]
        let subtitle = NSAttributedString(string: "Patient Health Report", attributes: subtitleAttrs)
        subtitle.draw(at: CGPoint(x: margin, y: 48))

        // Right side: report date
        let dateAttrs: [NSAttributedString.Key: Any] = [
            .font: font(10, weight: .regular),
            .foregroundColor: UIColor.white.withAlphaComponent(0.8)
        ]
        let dateStr = NSAttributedString(
            string: "Generated: \(Self.displayDateFormatter.string(from: Date()))",
            attributes: dateAttrs
        )
        let dateSize = dateStr.size()
        dateStr.draw(at: CGPoint(x: pageWidth - margin - dateSize.width, y: 20))

        // Page number on right
        let pageAttrs: [NSAttributedString.Key: Any] = [
            .font: font(10, weight: .medium),
            .foregroundColor: UIColor.white.withAlphaComponent(0.8)
        ]
        let pageStr = NSAttributedString(string: "Page \(pageNumber)", attributes: pageAttrs)
        let pageSize = pageStr.size()
        pageStr.draw(at: CGPoint(x: pageWidth - margin - pageSize.width, y: 40))

        // Teal accent line
        context.setFillColor(tealLight.cgColor)
        context.fill(CGRect(x: 0, y: headerHeight, width: pageWidth, height: 3))

        return headerHeight + 20
    }

    // MARK: - Drawing: Footer

    private func drawFooter(context: CGContext, pageNumber: Int) {
        let footerY = pageHeight - footerHeight

        // Light line
        context.setStrokeColor(borderGray.cgColor)
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: margin, y: footerY))
        context.addLine(to: CGPoint(x: pageWidth - margin, y: footerY))
        context.strokePath()

        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: font(8, weight: .regular),
            .foregroundColor: secondaryText
        ]

        let disclaimer = NSAttributedString(
            string: "This report is auto-generated by MedCare and is for informational purposes only. It does not replace professional medical advice.",
            attributes: footerAttrs
        )
        disclaimer.draw(in: CGRect(x: margin, y: footerY + 8, width: contentWidth - 60, height: 24))

        let pageAttrs: [NSAttributedString.Key: Any] = [
            .font: font(9, weight: .medium),
            .foregroundColor: secondaryText
        ]
        let pageStr = NSAttributedString(string: "\(pageNumber)", attributes: pageAttrs)
        let pageSize = pageStr.size()
        pageStr.draw(at: CGPoint(x: pageWidth - margin - pageSize.width, y: footerY + 10))
    }

    // MARK: - Drawing: Patient Info

    private func drawPatientInfo(context: CGContext, y: CGFloat, profile: UserProfile, dateRange: ClosedRange<Date>) -> CGFloat {
        var currentY = y

        currentY = drawSectionTitle(context: context, y: currentY, title: "PATIENT INFORMATION")

        // Info card background
        let cardHeight: CGFloat = 70
        drawRoundedRect(context: context, rect: CGRect(x: margin, y: currentY, width: contentWidth, height: cardHeight), color: lightGray, cornerRadius: 8)

        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: font(9, weight: .medium),
            .foregroundColor: secondaryText
        ]
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: font(12, weight: .semibold),
            .foregroundColor: darkText
        ]

        let colWidth = contentWidth / 4
        let fields: [(String, String)] = [
            ("Name", profile.name),
            ("Age", profile.age.map { "\($0) years" } ?? "N/A"),
            ("Blood Group", profile.bloodGroup ?? "N/A"),
            ("Gender", profile.gender?.rawValue ?? "N/A")
        ]

        for (i, field) in fields.enumerated() {
            let x = margin + CGFloat(i) * colWidth + 12
            NSAttributedString(string: field.0, attributes: labelAttrs)
                .draw(at: CGPoint(x: x, y: currentY + 12))
            NSAttributedString(string: field.1, attributes: valueAttrs)
                .draw(at: CGPoint(x: x, y: currentY + 28))
        }

        // Report period
        let periodAttrs: [NSAttributedString.Key: Any] = [
            .font: font(9, weight: .regular),
            .foregroundColor: secondaryText
        ]
        let periodStr = "Report Period: \(Self.shortDateFormatter.string(from: dateRange.lowerBound)) - \(Self.shortDateFormatter.string(from: dateRange.upperBound))"
        NSAttributedString(string: periodStr, attributes: periodAttrs)
            .draw(at: CGPoint(x: margin + 12, y: currentY + 50))

        return currentY + cardHeight + 16
    }

    // MARK: - Drawing: Health Score

    private func drawHealthScore(context: CGContext, y: CGFloat, healthScore: HealthScore) -> CGFloat {
        var currentY = y

        currentY = drawSectionTitle(context: context, y: currentY, title: "HEALTH SCORE")

        let cardHeight: CGFloat = 80
        drawRoundedRect(context: context, rect: CGRect(x: margin, y: currentY, width: contentWidth, height: cardHeight), color: lightGray, cornerRadius: 8)

        // Score circle
        let circleCenter = CGPoint(x: margin + 50, y: currentY + cardHeight / 2)
        let circleRadius: CGFloat = 28

        // Background circle
        context.setStrokeColor(borderGray.cgColor)
        context.setLineWidth(6)
        context.addArc(center: circleCenter, radius: circleRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        context.strokePath()

        // Score arc
        let scoreColor = gradeUIColor(healthScore.grade)
        context.setStrokeColor(scoreColor.cgColor)
        context.setLineWidth(6)
        context.setLineCap(.round)
        let startAngle: CGFloat = -.pi / 2
        let endAngle = startAngle + (.pi * 2 * CGFloat(healthScore.total) / 100)
        context.addArc(center: circleCenter, radius: circleRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        context.strokePath()
        context.setLineCap(.butt)

        // Score number
        let scoreAttrs: [NSAttributedString.Key: Any] = [
            .font: roundedFont(20, weight: .bold),
            .foregroundColor: scoreColor
        ]
        let scoreStr = NSAttributedString(string: "\(healthScore.total)", attributes: scoreAttrs)
        let scoreSize = scoreStr.size()
        scoreStr.draw(at: CGPoint(x: circleCenter.x - scoreSize.width / 2, y: circleCenter.y - scoreSize.height / 2))

        // Grade and trend text
        let gradeAttrs: [NSAttributedString.Key: Any] = [
            .font: roundedFont(18, weight: .bold),
            .foregroundColor: scoreColor
        ]
        NSAttributedString(string: "Grade: \(healthScore.grade.rawValue)", attributes: gradeAttrs)
            .draw(at: CGPoint(x: margin + 100, y: currentY + 15))

        let trendAttrs: [NSAttributedString.Key: Any] = [
            .font: font(11, weight: .medium),
            .foregroundColor: secondaryText
        ]
        let trendArrow: String
        switch healthScore.trend {
        case .improving: trendArrow = "Trend: Improving"
        case .stable: trendArrow = "Trend: Stable"
        case .declining: trendArrow = "Trend: Declining"
        }
        NSAttributedString(string: trendArrow, attributes: trendAttrs)
            .draw(at: CGPoint(x: margin + 100, y: currentY + 40))

        // Component breakdown on right
        let breakdownX = margin + contentWidth * 0.55
        let componentLabelAttrs: [NSAttributedString.Key: Any] = [
            .font: font(9, weight: .regular),
            .foregroundColor: secondaryText
        ]
        let componentValueAttrs: [NSAttributedString.Key: Any] = [
            .font: font(9, weight: .semibold),
            .foregroundColor: darkText
        ]
        let components = [
            ("Adherence", "\(healthScore.adherenceComponent)/40"),
            ("Symptoms", "\(healthScore.symptomComponent)/25"),
            ("Streak", "\(healthScore.streakComponent)/20"),
            ("Completeness", "\(healthScore.completenessComponent)/15")
        ]
        for (i, comp) in components.enumerated() {
            let cy = currentY + 12 + CGFloat(i) * 15
            NSAttributedString(string: comp.0, attributes: componentLabelAttrs)
                .draw(at: CGPoint(x: breakdownX, y: cy))
            NSAttributedString(string: comp.1, attributes: componentValueAttrs)
                .draw(at: CGPoint(x: breakdownX + 90, y: cy))
        }

        return currentY + cardHeight + 16
    }

    // MARK: - Drawing: Adherence Summary

    private func drawAdherenceSummary(
        context: CGContext, y: CGFloat,
        adherencePercent: Double,
        taken: Int, missed: Int, skipped: Int, total: Int
    ) -> CGFloat {
        var currentY = y
        currentY = drawSectionTitle(context: context, y: currentY, title: "ADHERENCE SUMMARY")

        let cardHeight: CGFloat = 55
        let colWidth = contentWidth / 4

        drawRoundedRect(context: context, rect: CGRect(x: margin, y: currentY, width: contentWidth, height: cardHeight), color: lightGray, cornerRadius: 8)

        let stats: [(String, String, UIColor)] = [
            ("Adherence", String(format: "%.0f%%", adherencePercent), adherencePercent >= 80 ? successGreen : (adherencePercent >= 50 ? warningAmber : errorRed)),
            ("Taken", "\(taken)", successGreen),
            ("Missed", "\(missed)", errorRed),
            ("Skipped", "\(skipped)", warningAmber)
        ]

        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: font(9, weight: .medium),
            .foregroundColor: secondaryText
        ]

        for (i, stat) in stats.enumerated() {
            let x = margin + CGFloat(i) * colWidth + 12
            NSAttributedString(string: stat.0, attributes: labelAttrs)
                .draw(at: CGPoint(x: x, y: currentY + 10))
            let valAttrs: [NSAttributedString.Key: Any] = [
                .font: roundedFont(16, weight: .bold),
                .foregroundColor: stat.2
            ]
            NSAttributedString(string: stat.1, attributes: valAttrs)
                .draw(at: CGPoint(x: x, y: currentY + 26))
        }

        return currentY + cardHeight + 16
    }

    // MARK: - Drawing: Adherence Heatmap

    private func drawAdherenceHeatmap(context: CGContext, y: CGFloat, doseLogs: [DoseLog], dateRange: ClosedRange<Date>) -> CGFloat {
        var currentY = y
        currentY = drawSectionTitle(context: context, y: currentY, title: "DAILY ADHERENCE")

        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: dateRange.lowerBound)
        let endDate = calendar.startOfDay(for: dateRange.upperBound)

        let totalDays = max(1, calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 1)
        let columns = min(totalDays, 35) // max 5 weeks displayed
        let cellSize: CGFloat = min(14, (contentWidth - 40) / CGFloat(columns))
        let cellGap: CGFloat = 2

        // Day labels
        let dayLabelAttrs: [NSAttributedString.Key: Any] = [
            .font: font(7, weight: .medium),
            .foregroundColor: secondaryText
        ]
        let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

        // Build daily adherence data
        var dailyAdherence: [Date: Double] = [:]
        for dayOffset in 0..<totalDays {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }
            let dayStart = calendar.startOfDay(for: day)
            guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { continue }

            let dayLogs = doseLogs.filter { $0.scheduledTime >= dayStart && $0.scheduledTime < dayEnd }
            if dayLogs.isEmpty {
                dailyAdherence[dayStart] = -1 // no data
            } else {
                let taken = dayLogs.filter { $0.status == .taken }.count
                dailyAdherence[dayStart] = Double(taken) / Double(dayLogs.count)
            }
        }

        // Draw grid — rows = 7 (days of week), columns = weeks
        let weeks = (totalDays + 6) / 7
        let gridWidth = CGFloat(weeks) * (cellSize + cellGap)
        let gridStartX = margin + (contentWidth - gridWidth - 16) / 2 + 16

        // Day of week labels
        for row in 0..<7 {
            let labelY = currentY + CGFloat(row) * (cellSize + cellGap) + 2
            NSAttributedString(string: dayLabels[row], attributes: dayLabelAttrs)
                .draw(at: CGPoint(x: margin + 4, y: labelY))
        }

        for dayOffset in 0..<totalDays {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }
            let dayStart = calendar.startOfDay(for: day)
            let weekday = (calendar.component(.weekday, from: day) + 5) % 7 // Mon=0
            let weekIndex = dayOffset / 7

            let cellX = gridStartX + CGFloat(weekIndex) * (cellSize + cellGap)
            let cellY = currentY + CGFloat(weekday) * (cellSize + cellGap)
            let cellRect = CGRect(x: cellX, y: cellY, width: cellSize, height: cellSize)

            let adherence = dailyAdherence[dayStart] ?? -1
            let cellColor: UIColor
            if adherence < 0 {
                cellColor = borderGray
            } else if adherence >= 0.9 {
                cellColor = successGreen
            } else if adherence >= 0.5 {
                cellColor = warningAmber
            } else {
                cellColor = errorRed.withAlphaComponent(0.7)
            }

            drawRoundedRect(context: context, rect: cellRect, color: cellColor, cornerRadius: 2)
        }

        let gridHeight = 7 * (cellSize + cellGap)

        // Legend
        let legendY = currentY + gridHeight + 6
        let legendAttrs: [NSAttributedString.Key: Any] = [
            .font: font(7, weight: .regular),
            .foregroundColor: secondaryText
        ]
        let legendItems: [(String, UIColor)] = [
            ("No data", borderGray),
            ("<50%", errorRed.withAlphaComponent(0.7)),
            ("50-89%", warningAmber),
            ("90%+", successGreen)
        ]
        var legendX = margin + 12.0
        for item in legendItems {
            drawRoundedRect(context: context, rect: CGRect(x: legendX, y: legendY + 1, width: 8, height: 8), color: item.1, cornerRadius: 2)
            legendX += 12
            let legendLabel = NSAttributedString(string: item.0, attributes: legendAttrs)
            legendLabel.draw(at: CGPoint(x: legendX, y: legendY))
            legendX += legendLabel.size().width + 12
        }

        return legendY + 24
    }

    // MARK: - Drawing: Medications Table

    private func drawMedicationsTable(context: CGContext, y: CGFloat, medicines: [Medicine]) -> CGFloat {
        var currentY = y
        currentY = drawSectionTitle(context: context, y: currentY, title: "CURRENT MEDICATIONS")

        if medicines.isEmpty {
            let emptyAttrs: [NSAttributedString.Key: Any] = [
                .font: font(11, weight: .regular),
                .foregroundColor: secondaryText
            ]
            NSAttributedString(string: "No active medications.", attributes: emptyAttrs)
                .draw(at: CGPoint(x: margin + 8, y: currentY))
            return currentY + 24
        }

        // Table header
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: font(9, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        let rowHeight: CGFloat = 22
        let headerRect = CGRect(x: margin, y: currentY, width: contentWidth, height: rowHeight)

        drawRoundedTopRect(context: context, rect: headerRect, color: tealColor, cornerRadius: 6)

        let cols: [(String, CGFloat)] = [
            ("Medicine", 0),
            ("Dosage", 0.35),
            ("Form", 0.52),
            ("Frequency", 0.65),
            ("Timing", 0.82)
        ]

        for col in cols {
            let x = margin + contentWidth * col.1 + 8
            NSAttributedString(string: col.0, attributes: headerAttrs)
                .draw(at: CGPoint(x: x, y: currentY + 5))
        }
        currentY += rowHeight

        // Rows
        let cellAttrs: [NSAttributedString.Key: Any] = [
            .font: font(9, weight: .regular),
            .foregroundColor: darkText
        ]
        let cellBoldAttrs: [NSAttributedString.Key: Any] = [
            .font: font(9, weight: .semibold),
            .foregroundColor: darkText
        ]

        for (i, med) in medicines.enumerated() {
            let bgColor = i % 2 == 0 ? UIColor.white : lightGray
            let isLast = i == medicines.count - 1
            let rowRect = CGRect(x: margin, y: currentY, width: contentWidth, height: rowHeight)

            if isLast {
                drawRoundedBottomRect(context: context, rect: rowRect, color: bgColor, cornerRadius: 6)
            } else {
                context.setFillColor(bgColor.cgColor)
                context.fill(rowRect)
            }

            // Border
            context.setStrokeColor(borderGray.cgColor)
            context.setLineWidth(0.5)
            context.move(to: CGPoint(x: margin, y: currentY + rowHeight))
            context.addLine(to: CGPoint(x: margin + contentWidth, y: currentY + rowHeight))
            context.strokePath()

            let timingStr = med.timing.map { $0.displayName }.joined(separator: ", ")

            let rowData: [(String, CGFloat, [NSAttributedString.Key: Any])] = [
                (med.brandName, 0, cellBoldAttrs),
                (med.dosage, 0.35, cellAttrs),
                (med.doseForm.rawValue, 0.52, cellAttrs),
                (med.frequency.rawValue, 0.65, cellAttrs),
                (timingStr, 0.82, cellAttrs)
            ]

            for data in rowData {
                let x = margin + contentWidth * data.1 + 8
                NSAttributedString(string: data.0, attributes: data.2)
                    .draw(in: CGRect(x: x, y: currentY + 5, width: contentWidth * 0.17, height: rowHeight - 4))
            }

            currentY += rowHeight
        }

        // Outer border
        let tableRect = CGRect(x: margin, y: y + 26, width: contentWidth, height: currentY - y - 26)
        context.setStrokeColor(borderGray.cgColor)
        context.setLineWidth(0.5)
        let borderPath = UIBezierPath(roundedRect: tableRect, cornerRadius: 6)
        context.addPath(borderPath.cgPath)
        context.strokePath()

        return currentY + 16
    }

    // MARK: - Drawing: Symptom Summary

    private func drawSymptomSummary(context: CGContext, y: CGFloat, symptomLogs: [SymptomLog]) -> CGFloat {
        var currentY = y
        currentY = drawSectionTitle(context: context, y: currentY, title: "SYMPTOM SUMMARY")

        // Feeling distribution
        let feelingCounts: [(FeelingLevel, Int)] = FeelingLevel.allCases.map { level in
            (level, symptomLogs.filter { $0.overallFeeling == level }.count)
        }

        let barMaxWidth: CGFloat = contentWidth * 0.5
        let totalLogs = max(1, symptomLogs.count)

        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: font(10, weight: .medium),
            .foregroundColor: darkText
        ]
        let countAttrs: [NSAttributedString.Key: Any] = [
            .font: font(9, weight: .regular),
            .foregroundColor: secondaryText
        ]

        for feeling in feelingCounts {
            let barWidth = barMaxWidth * CGFloat(feeling.1) / CGFloat(totalLogs)
            let barColor = feelingColor(feeling.0)

            // Label
            NSAttributedString(string: feeling.0.label, attributes: labelAttrs)
                .draw(at: CGPoint(x: margin + 8, y: currentY))

            // Bar
            let barX = margin + 80.0
            let barRect = CGRect(x: barX, y: currentY + 2, width: max(barWidth, 2), height: 12)
            drawRoundedRect(context: context, rect: barRect, color: barColor, cornerRadius: 3)

            // Count
            NSAttributedString(string: "\(feeling.1)", attributes: countAttrs)
                .draw(at: CGPoint(x: barX + barWidth + 6, y: currentY + 1))

            currentY += 20
        }

        // Common symptoms
        let allSymptoms = symptomLogs.flatMap { $0.symptoms }
        if !allSymptoms.isEmpty {
            currentY += 4
            let symptomFreq = Dictionary(grouping: allSymptoms, by: { $0.name })
                .mapValues { $0.count }
                .sorted { $0.value > $1.value }
                .prefix(5)

            let symTitleAttrs: [NSAttributedString.Key: Any] = [
                .font: font(10, weight: .semibold),
                .foregroundColor: darkText
            ]
            NSAttributedString(string: "Most Reported Symptoms:", attributes: symTitleAttrs)
                .draw(at: CGPoint(x: margin + 8, y: currentY))
            currentY += 16

            for sym in symptomFreq {
                let symAttrs: [NSAttributedString.Key: Any] = [
                    .font: font(9, weight: .regular),
                    .foregroundColor: darkText
                ]
                NSAttributedString(string: "  \(sym.key) (\(sym.value)x)", attributes: symAttrs)
                    .draw(at: CGPoint(x: margin + 16, y: currentY))
                currentY += 14
            }
        }

        return currentY + 12
    }

    // MARK: - Drawing: Active Episodes

    private func drawActiveEpisodes(context: CGContext, y: CGFloat, episodes: [Episode]) -> CGFloat {
        var currentY = y
        currentY = drawSectionTitle(context: context, y: currentY, title: "ACTIVE EPISODES")

        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: font(10, weight: .semibold),
            .foregroundColor: darkText
        ]
        let detailAttrs: [NSAttributedString.Key: Any] = [
            .font: font(9, weight: .regular),
            .foregroundColor: secondaryText
        ]

        for episode in episodes.prefix(5) {
            let cardHeight: CGFloat = 44
            drawRoundedRect(
                context: context,
                rect: CGRect(x: margin, y: currentY, width: contentWidth, height: cardHeight),
                color: lightGray,
                cornerRadius: 6
            )

            // Color indicator
            let typeColor = episodeTypeColor(episode.episodeType)
            drawRoundedRect(
                context: context,
                rect: CGRect(x: margin + 4, y: currentY + 8, width: 4, height: cardHeight - 16),
                color: typeColor,
                cornerRadius: 2
            )

            NSAttributedString(string: episode.title, attributes: labelAttrs)
                .draw(at: CGPoint(x: margin + 16, y: currentY + 6))

            var details: [String] = [episode.episodeType.rawValue]
            if let doctor = episode.doctorName { details.append("Dr. \(doctor)") }
            if let diagnosis = episode.diagnosis { details.append(diagnosis) }

            NSAttributedString(string: details.joined(separator: " | "), attributes: detailAttrs)
                .draw(in: CGRect(x: margin + 16, y: currentY + 24, width: contentWidth - 32, height: 14))

            currentY += cardHeight + 6
        }

        return currentY + 8
    }

    // MARK: - Drawing: Insights

    private func drawInsights(context: CGContext, y: CGFloat, healthScore: HealthScore) -> CGFloat {
        var currentY = y
        currentY = drawSectionTitle(context: context, y: currentY, title: "KEY INSIGHTS & RECOMMENDATIONS")

        // Tip box
        let tipText = healthScore.tip
        let tipAttrs: [NSAttributedString.Key: Any] = [
            .font: font(10, weight: .regular),
            .foregroundColor: darkText
        ]
        let tipStr = NSAttributedString(string: tipText, attributes: tipAttrs)
        let tipBounds = tipStr.boundingRect(
            with: CGSize(width: contentWidth - 40, height: 200),
            options: [.usesLineFragmentOrigin],
            context: nil
        )
        let tipCardHeight = max(tipBounds.height + 20, 40)

        // Light teal background for tip
        let tipBg = tealColor.withAlphaComponent(0.08)
        drawRoundedRect(
            context: context,
            rect: CGRect(x: margin, y: currentY, width: contentWidth, height: tipCardHeight),
            color: tipBg,
            cornerRadius: 8
        )

        // Teal left accent bar
        drawRoundedRect(
            context: context,
            rect: CGRect(x: margin, y: currentY, width: 4, height: tipCardHeight),
            color: tealColor,
            cornerRadius: 2
        )

        tipStr.draw(in: CGRect(x: margin + 16, y: currentY + 10, width: contentWidth - 40, height: tipCardHeight))

        return currentY + tipCardHeight + 16
    }

    // MARK: - Drawing Helpers

    private func drawSectionTitle(context: CGContext, y: CGFloat, title: String) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font(11, weight: .bold),
            .foregroundColor: tealColor,
            .kern: 1.2
        ]
        NSAttributedString(string: title, attributes: attrs).draw(at: CGPoint(x: margin, y: y))

        // Underline
        context.setStrokeColor(tealColor.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: margin, y: y + 16))
        context.addLine(to: CGPoint(x: margin + contentWidth, y: y + 16))
        context.strokePath()

        return y + 24
    }

    private func drawRoundedRect(context: CGContext, rect: CGRect, color: UIColor, cornerRadius: CGFloat) {
        context.setFillColor(color.cgColor)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        context.addPath(path.cgPath)
        context.fillPath()
    }

    private func drawRoundedTopRect(context: CGContext, rect: CGRect, color: UIColor, cornerRadius: CGFloat) {
        context.setFillColor(color.cgColor)
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
        )
        context.addPath(path.cgPath)
        context.fillPath()
    }

    private func drawRoundedBottomRect(context: CGContext, rect: CGRect, color: UIColor, cornerRadius: CGFloat) {
        context.setFillColor(color.cgColor)
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.bottomLeft, .bottomRight],
            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
        )
        context.addPath(path.cgPath)
        context.fillPath()
    }

    // MARK: - Color Helpers

    private func gradeUIColor(_ grade: HealthGrade) -> UIColor {
        switch grade {
        case .aPlus, .a: return successGreen
        case .b: return UIColor(red: 0, green: 122/255, blue: 1, alpha: 1)
        case .c: return warningAmber
        case .d: return UIColor(red: 249/255, green: 112/255, blue: 102/255, alpha: 1)
        case .f: return errorRed
        }
    }

    private func feelingColor(_ level: FeelingLevel) -> UIColor {
        switch level {
        case .great: return successGreen
        case .good: return UIColor(red: 52/255, green: 199/255, blue: 89/255, alpha: 0.7)
        case .okay: return warningAmber
        case .bad: return UIColor(red: 249/255, green: 112/255, blue: 102/255, alpha: 1)
        case .terrible: return errorRed
        }
    }

    private func episodeTypeColor(_ type: EpisodeType) -> UIColor {
        switch type {
        case .acute: return UIColor(red: 249/255, green: 107/255, blue: 107/255, alpha: 1)
        case .chronic: return warningAmber
        case .postDischarge: return UIColor(red: 0, green: 122/255, blue: 1, alpha: 1)
        case .preventive: return successGreen
        }
    }

    // MARK: - Date Formatters

    private static let displayDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    private static let fileDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
}
