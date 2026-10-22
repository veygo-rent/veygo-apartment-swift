//
//  Intents.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 10/22/26.
//

import AppIntents
import Foundation

struct VeygoAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: PastRentalIntent(),
            phrases: [
                "Show my past car rentals from \(.applicationName)",
                "Get my past rentals from \(.applicationName)",
                "Show my rental history in \(.applicationName)"
            ],
            shortTitle: "Past Rentals",
            systemImageName: "car.fill"
        )
    }
}

struct PastRentalIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Past Rentals"
    static var description = IntentDescription("Get past rental dates, recorded trip durations, and confirmation numbers.")

    @AppDependency private var session: Session

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[String]> & ProvidesDialog {
        do {
            let agreements = try await fetchPastRentals().sorted {
                ($0.actualPickupTime ?? $0.rsvpPickupTime) > ($1.actualPickupTime ?? $1.rsvpPickupTime)
            }
            let summaries = agreements.map { RentalSummary.text(for: $0) }
            var spokenSummary = agreements.isEmpty
                ? "You have no past rentals."
                : "Found \(agreements.count) past rental \(agreements.count == 1 ? "record" : "records"). "
                    + summaries.prefix(3).joined(separator: " ")
            if agreements.count > 3 {
                spokenSummary += " These are your three most recent records."
            }
            let results = zip(agreements, summaries).map { agreement, summary in
                "\(summary) Confirmation: \(agreement.confirmation)."
            }
            return .result(value: results, dialog: IntentDialog(stringLiteral: spokenSummary))
        } catch let error as VeygoError {
            // Surface a readable failure to Shortcuts instead of a successful empty result.
            throw RentalIntentError(message: error.display.message)
        }
    }

    @MainActor
    private func fetchPastRentals() async throws -> [Agreement] {
        let token = session.token
        let userId = session.userId
        guard !token.isEmpty, userId > 0 else {
            throw VeygoError.unauthorized(.E401)
        }

        let request = veygoCurlRequest(
            url: "/api/v1/agreement/past",
            method: .get,
            headers: ["auth": "\(token)$\(userId)"]
        )
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw VeygoError.unknown
            }
            let httpCode = httpResponse.statusCode

            if httpCode == 200 {
                return try VeygoJsonStandard.shared.decoder.decode([Agreement].self, from: data)
            } else if httpCode == 401 {
                let decodedError = try VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)
                throw VeygoError.unauthorized(decodedError)
            } else {
                let decodedError = try VeygoJsonStandard.shared.decoder.decode(ErrorResponse.self, from: data)
                throw VeygoError.server(status: httpCode, error: decodedError)
            }
        } catch let error as URLError {
            throw VeygoError.network(error)
        } catch _ as DecodingError {
            throw VeygoError.decoding
        } catch let error as VeygoError {
            throw error
        } catch {
            throw VeygoError.unknown
        }
    }
}

private enum RentalSummary {
    static func text(for agreement: Agreement) -> String {
        // This response has no rental-location timezone; explicitly label device-local times.
        let dateFormatter = DateFormatter()
        dateFormatter.locale = .autoupdatingCurrent
        dateFormatter.timeZone = .autoupdatingCurrent
        dateFormatter.setLocalizedDateFormatFromTemplate("MMM d yyyy h mm a z")

        if let pickup = agreement.actualPickupTime {
            let start = dateFormatter.string(from: pickup)
            if let dropOff = agreement.actualDropOffTime, dropOff >= pickup {
                let durationFormatter = DateComponentsFormatter()
                durationFormatter.allowedUnits = [.day, .hour, .minute]
                durationFormatter.unitsStyle = .full
                durationFormatter.maximumUnitCount = 2
                let seconds = dropOff.timeIntervalSince(pickup)
                let duration = seconds < 60
                    ? "less than a minute"
                    : "about \(durationFormatter.string(from: seconds) ?? "an unknown duration")"
                return "Your rental on \(start) lasted \(duration)."
            }
            return "Your rental started on \(start). No valid return time is recorded."
        }

        let start = dateFormatter.string(from: agreement.rsvpPickupTime)
        let end = dateFormatter.string(from: agreement.rsvpDropOffTime)
        return "You had a reservation from \(start) to \(end). No pickup is recorded."
    }
}

private struct RentalIntentError: LocalizedError {
    let message: String

    var errorDescription: String? { message }
}
