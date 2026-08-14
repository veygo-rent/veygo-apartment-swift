//
//  Session.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou.
//

import Foundation
import Observation

@Observable
@MainActor
final class Session {
    private enum Keys {
        static let token = "token"
        static let userId = "user_id"
    }

    /// The auth token. Empty string means "no valid credential".
    private(set) var token: String

    /// The current user's id. `0` means "not authenticated".
    private(set) var userId: Int

    /// The loaded renter profile. In-memory only — fetched fresh each launch
    /// using `token`/`userId`. `nil` until loaded (or after logout).
    private(set) var renter: PublishRenter?

    /// True when there are stored credentials to fetch the profile with.
    /// Use this on launch to decide whether to attempt a profile fetch.
    var isAuthenticated: Bool {
        !token.isEmpty && userId != 0
    }

    /// True when the renter profile has been loaded into memory.
    /// Use this to gate authenticated UI that needs the user's data.
    var isLoggedIn: Bool {
        renter != nil
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.token = defaults.string(forKey: Keys.token) ?? ""
        self.userId = defaults.integer(forKey: Keys.userId)
        self.renter = nil   // always fetched fresh after launch
    }

    private let defaults: UserDefaults

    /// Store credentials after a successful login and persist them. Pass the
    /// renter if the login response already includes the profile
    func login(token: String, userId: Int, renter: PublishRenter) {
        self.token = token
        self.userId = userId
        self.renter = renter
        defaults.set(token, forKey: Keys.token)
        defaults.set(userId, forKey: Keys.userId)
    }
    
    /// Set the in-memory renter after fetching it with stored credentials.
    func setRenter(_ renter: PublishRenter) {
        self.renter = renter
    }

    /// Clear credentials and profile on logout or when the token is rejected
    /// as invalid.
    func clear() {
        token = ""
        userId = 0
        renter = nil
        defaults.removeObject(forKey: Keys.token)
        defaults.removeObject(forKey: Keys.userId)
    }
    
    /// Retrieve current renter
    func getRenter() -> PublishRenter? {
        renter
    }
}
