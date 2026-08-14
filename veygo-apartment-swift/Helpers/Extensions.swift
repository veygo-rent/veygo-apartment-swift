//
//  Extensions.swift
//  veygo-apartment-swift
//
//  Created by Shenghong Zhou on 8/12/26.
//

import Foundation

extension Array where Element: Identifiable {
    func getItemBy(id: Element.ID) -> Element? {
        return self.first { $0.id == id }
    }
}

protocol HasName {
    var name: String { get }
}
