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

struct PastRentalIntent: AppIntent, PredictableIntent {
    static var title: LocalizedStringResource = "Get Past Rentals"
    static var description = IntentDescription("Get past rental dates, recorded trip durations, and confirmation numbers.")

    static var predictionConfiguration: some IntentPredictionConfiguration {
        IntentPrediction {
            DisplayRepresentation(title: "View past rentals", image: .init(systemName: "car.fill"))
        }
    }

    @AppDependency private var session: Session

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[RentalEntity]> & ProvidesDialog {
        do {
            let agreements = try await PastRentalService.fetch(session: session).sorted {
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
            let results = try await PastRentalService.entities(for: agreements, session: session)
            return .result(value: results, dialog: IntentDialog(stringLiteral: spokenSummary))
        } catch let error as VeygoError {
            // Surface a readable failure to Shortcuts instead of a successful empty result.
            throw RentalIntentError(message: error.display.message)
        }
    }

}

private enum PastRentalService {
    @MainActor
    static func fetch(session: Session) async throws -> [Agreement] {
        try await request("/api/v1/agreement/past", session: session)
    }

    @MainActor
    static func entities(for agreements: [Agreement], session: Session) async throws -> [RentalEntity] {
        var results: [RentalEntity] = []
        for agreement in agreements {
            try Task.checkCancellation()
            var entity = RentalEntity(agreement: agreement)
            do {
                let details: VehicleDetails = try await request(
                    "/api/v1/agreement/\(agreement.confirmation)", session: session
                )
                entity.vehicleName = details.vehicle.name
                entity.vehicleYear = details.vehicle.year
                entity.vehicleMake = details.vehicle.make
                entity.vehicleModel = details.vehicle.model
            } catch let error as VeygoError {
                if case .unauthorized = error { throw error }
                if case .network(let underlying) = error, underlying.code == .cancelled { throw error }
                // Optional enrichment must not hide an otherwise available rental record.
            }
            results.append(entity)
        }
        return results
    }

    private struct VehicleDetails: Decodable {
        let vehicle: Vehicle
        struct Vehicle: Decodable {
            let name: String
            let year: String
            let make: String
            let model: String
        }
    }

    @MainActor
    private static func request<Value: Decodable>(_ path: String, session: Session) async throws -> Value {
        let token = session.token
        let userId = session.userId
        guard !token.isEmpty, userId > 0 else {
            throw VeygoError.unauthorized(.E401)
        }

        let request = veygoCurlRequest(
            url: path,
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
                return try VeygoJsonStandard.shared.decoder.decode(Value.self, from: data)
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

struct RentalEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Rental"
    static var defaultQuery = RentalEntityQuery()

    let id: Int
    @Property(title: "Confirmation Number") var confirmation: String
    @Property(title: "Agreement Status") var status: String
    @Property(title: "Scheduled Pickup") var scheduledPickup: Date
    @Property(title: "Scheduled Return") var scheduledReturn: Date
    @Property(title: "Actual Pickup") var actualPickup: Date?
    @Property(title: "Actual Return") var actualReturn: Date?
    @Property(title: "Recorded Duration in Minutes") var durationMinutes: Double?
    @Property(title: "Vehicle Name") var vehicleName: String?
    @Property(title: "Vehicle Year") var vehicleYear: String?
    @Property(title: "Vehicle Make") var vehicleMake: String?
    @Property(title: "Vehicle Model") var vehicleModel: String?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(vehicleName ?? "Rental") — \(confirmation)",
            subtitle: "\(scheduledPickup.formatted(date: .abbreviated, time: .shortened))",
            image: .init(systemName: "car.fill")
        )
    }

    init(agreement: Agreement) {
        id = agreement.id
        confirmation = agreement.confirmation
        status = agreement.status.rawValue
        scheduledPickup = agreement.rsvpPickupTime
        scheduledReturn = agreement.rsvpDropOffTime
        actualPickup = agreement.actualPickupTime
        actualReturn = agreement.actualDropOffTime
        vehicleName = nil
        vehicleYear = nil
        vehicleMake = nil
        vehicleModel = nil
        if let pickup = agreement.actualPickupTime,
           let dropOff = agreement.actualDropOffTime, dropOff >= pickup {
            durationMinutes = dropOff.timeIntervalSince(pickup) / 60
        } else {
            durationMinutes = nil
        }
    }
}

struct RentalEntityQuery: EntityQuery {
    @AppDependency private var session: Session

    @MainActor
    func entities(for identifiers: [RentalEntity.ID]) async throws -> [RentalEntity] {
        guard !identifiers.isEmpty else { return [] }
        let rentals = try await loadRentals(identifiers: Set(identifiers))
        // Resolve against the currently authenticated account; never return cached account data.
        return identifiers.compactMap { id in rentals.first { $0.id == id } }
    }

    @MainActor
    func suggestedEntities() async throws -> [RentalEntity] {
        try await loadRentals(limit: 10)
    }

    @MainActor
    private func loadRentals(identifiers: Set<Int>? = nil, limit: Int? = nil) async throws -> [RentalEntity] {
        do {
            let agreements = try await PastRentalService.fetch(session: session)
                .sorted {
                    ($0.actualPickupTime ?? $0.rsvpPickupTime) > ($1.actualPickupTime ?? $1.rsvpPickupTime)
                }
            let matching = agreements.filter { identifiers?.contains($0.id) ?? true }
            let selected = limit.map { Array(matching.prefix($0)) } ?? matching
            return try await PastRentalService.entities(for: selected, session: session)
        } catch let error as VeygoError {
            throw RentalIntentError(message: error.display.message)
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
