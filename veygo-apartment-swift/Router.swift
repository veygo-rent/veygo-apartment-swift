//
//  Router.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou.
//

import SwiftUI

@Observable
@MainActor
final class Router {
    var path = NavigationPath()

    func push<V: Hashable>(_ value: V) {
        path.append(value)
    }

    func pop() {
        if !path.isEmpty { path.removeLast() }
    }

    func popToRoot() {
        path = NavigationPath()
    }
}
