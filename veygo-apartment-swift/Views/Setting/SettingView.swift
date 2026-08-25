//
//  SettingView.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 8/13/26.
//

import SwiftUI
import Crisp
import WebKit

struct SettingView: View {
    @Environment(Session.self) private var session
    @Environment(Router.self) private var router

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""

    @State private var showHelpCenter: Bool = false

    var body: some View {
        // The tab's root content — NO inner NavigationStack. AppView owns the
        // single outer stack and registers the destinations.
        Group {
            if let user = session.renter {
                settingsList(user: user)
            } else {
                EmptyView()
            }
        }
        .sheet(isPresented: $showHelpCenter) {
            ChatView()
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }

    @ViewBuilder
    private func settingsList(user: PublishRenter) -> some View {
        List {
            if user.employeeTier != .user && user.emailIsValid() {
                Section {
                    NavigationLink("Upload Vehicle Snapshot", value: SettingDestination.submitVehicleSnapshot)
                } header: {
                    Text("Admin").fontWeight(.light)
                }
                .listRowBackground(Color.cardBG)
                .foregroundStyle(Color.textBlackSecondary)
                .listSectionSeparator(.hidden)
            }

            Section {
                NavigationLink("Privacy Policy", value: SettingDestination.privacyPolicy)
                NavigationLink("Member Agreement", value: SettingDestination.memberAgreement)
                NavigationLink("Rental Agreement", value: SettingDestination.rentalAgreement)
                NavigationLink("Terms of Use", value: SettingDestination.termsOfUse)
            } header: {
                Text("Legal").fontWeight(.light)
            }
            .listRowBackground(Color.cardBG)
            .foregroundStyle(Color.textBlackSecondary)
            .listSectionSeparator(.hidden)

            Section {
                NavigationLink("Roadside Assistance", value: SettingDestination.roadside)
                Button {
                    showHelpCenter.toggle()
                } label: {
                    Text("Help Center")
                }
            } header: {
                Text("Support").fontWeight(.light)
            }
            .listRowBackground(Color.cardBG)
            .foregroundStyle(Color.textBlackSecondary)
            .listSectionSeparator(.hidden)

            Section {
                Button(role: .destructive) {
                    Task { await logout() }
                } label: {
                    Text("Log Out")
                        .foregroundStyle(Color.invalidRed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .listRowBackground(Color.cardBG)
            .listSectionSeparator(.hidden)

            Section {
                ShortTextLink(text: "Request deleting account") {
                    router.push(SettingDestination.deleteAccount)
                }
                .listRowBackground(Color.clear)
            }
            .listSectionSeparator(.hidden)
            .listSectionSpacing(0)
        }
        .listStyle(.automatic)
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .background(Color.mainBG, ignoresSafeAreaEdges: .all)
    }

    // MARK: - Logout

    private func logout() async {
        do {
            try await logoutRequest()
            session.clear()   // success → clear credentials, RootView drops to login
        } catch let error as VeygoError {
            present(error.display)
        } catch {
            present(.E_DEFAULT)
        }
    }

    private func logoutRequest() async throws {
        let token = session.token
        let userId = session.userId
        guard !token.isEmpty, userId > 0 else {
            throw VeygoError.unknown
        }

        let request = veygoCurlRequest(
            url: "/api/v1/user/token",
            method: .delete,
            headers: ["auth": "\(token)$\(userId)"]
        )
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw VeygoError.unknown
            }
            let httpCode = httpResponse.statusCode

            if httpCode == 200 {
                return
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

    // MARK: - Alert

    private func present(_ error: ErrorResponse) {
        present(title: error.title, message: error.message)
    }

    private func present(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}
