/*
 * Copyright (c) 2026, Filiph Sandström <filfat@hotmail.se>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

import AppKit
import Foundation
import Observation

public struct FindInPageState {
    public var query: String = ""
    public var caseSensitive: Bool = false
    public var currentMatch: Int = 0
    public var total: Int? = nil
    public var focusToken: Int = 0
}

@Observable
public final class TabModel {
    public var findInPage = FindInPageState()
}

@objc(LBTabModel)
public final class TabModelObjC: NSObject {
    public let model: TabModel

    @objc public override init() {
        self.model = TabModel()
        super.init()
    }

    @objc public func setFindInPageQuery(_ query: String, caseSensitive: Bool) {
        model.findInPage.query = query
        model.findInPage.caseSensitive = caseSensitive
    }

    @objc public func setFindInPageResult(_ result: LBFindInPageResult) {
        model.findInPage.currentMatch = result.currentMatch
        model.findInPage.total = result.hasTotal ? result.total : nil
    }
}
