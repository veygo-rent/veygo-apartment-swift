//
//  RootView.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou.
//

import SwiftUI

struct RootView: View {
    @Environment(Session.self) private var session

    @State private var logoScale: CGFloat = 1.0
    @State private var logoOpacity: Double = 1.0
    @State private var didLoad = false
    @State private var showDestination = false
    @State private var hasAppearedOnce = false

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var clearUserTriggered: Bool = false

    var body: some View {
        ZStack {
            // Destination underneath, revealed as the logo fades away.
            if showDestination {
                destinationView
                    .transition(.opacity)
                    .onAppear { hasAppearedOnce = true }
            }

            // Logo overlay — scales up and fades out on `didLoad`.
            if !showDestination {
                launchLogo
            }
        }
        .animation(.easeInOut(duration: 0.35), value: session.isLoggedIn)
        .task { await decideDestination() }
        .onChange(of: didLoad) {
            // Play the scale-up + fade-out, then swap in the destination.
            withAnimation(.easeInOut(duration: 2)) {
                logoScale = 1.2
                logoOpacity = 0.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showDestination = true
                }
            }
        }
    }

    private var launchLogo: some View {
        VStack {
            Spacer()
            Image("VeygoLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 250)
                .offset(y: -50)
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                .animation(.easeInOut(duration: 2), value: logoScale)
                .animation(.easeInOut(duration: 2), value: logoOpacity)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.mainBG)
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var destinationView: some View {
        if session.renter != nil {
            AppView()
                .transition(hasAppearedOnce ? .move(edge: .trailing) : .identity)
        } else {
            LoginView()
                .transition(hasAppearedOnce ? .move(edge: .leading) : .identity)
        }
    }

    private func decideDestination() async {
        if session.isAuthenticated {
            do {
                let renter = try await fetchCurrentRenter()
                session.setRenter(renter)
            } catch {
                session.clear()
            }
        }

        didLoad = true
    }

    private func fetchCurrentRenter() async throws -> PublishRenter {
        let request = veygoCurlRequest(
            url: "/api/v1/user/retrieve",
            method: .get,
            headers: ["auth": "\(session.token)$\(session.userId)"]
        )
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            // URLError
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw VeygoError.unknown
            }
            let httpCode = httpResponse.statusCode
            
            if httpCode == 200 {
                let decodedRenter = try VeygoJsonStandard.shared.decoder.decode(PublishRenter.self, from: data)
                // DecodingError
                
                return decodedRenter
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
