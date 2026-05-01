/*
 * Copyright (c) 2024, Tim Flynn <trflynn89@serenityos.org>
 * Copyright (c) 2026, Filiph Sandström <filfat@hotmail.se>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

import AppKit
import SwiftUI

private struct SearchPanelView: View {
    @Bindable var model: TabModel
    let onPrev: () -> Void
    let onNext: () -> Void
    let onClose: () -> Void
    let onQueryChange: (String, Bool) -> Void
    @FocusState private var fieldFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            TextField("Search", text: $model.findInPage.query)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)
                .focused($fieldFocused)
                .onSubmit(onNext)
                .onChange(of: model.findInPage.query) { _, newValue in
                    onQueryChange(newValue, model.findInPage.caseSensitive)
                }
            Button(action: onPrev) {
                Image(systemName: "chevron.up")
            }
            .buttonStyle(.borderless)
            .help("Find Previous Match")
            Button(action: onNext) {
                Image(systemName: "chevron.down")
            }
            .buttonStyle(.borderless)
            .help("Find Next Match")
            Toggle("Match Case", isOn: $model.findInPage.caseSensitive)
                .toggleStyle(.checkbox)
                .onChange(of: model.findInPage.caseSensitive) { _, newValue in
                    onQueryChange(model.findInPage.query, newValue)
                }
            Text(resultText)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
            Spacer()
            Button("Done", action: onClose)
                .help("Close Search Bar")
        }
        .padding(.horizontal, 8)
        .onChange(of: model.findInPage.focusToken) { _, _ in
            fieldFocused = true
        }
    }

    private var resultText: String {
        let state = model.findInPage
        guard let total = state.total else { return "" }
        if total == 0 { return "Phrase not found" }
        return "\(state.currentMatch) of \(total) matches"
    }
}

@objc(SearchPanelDelegate)
public protocol SearchPanelDelegate: NSObjectProtocol {
    func searchPanelDidRequestPrevious()
    func searchPanelDidRequestNext()
    func searchPanelDidRequestClose()
    func searchPanelDidUpdateQuery(_ query: String, caseSensitive: Bool)
}

@objc(SearchPanel)
public final class SearchPanel: NSView {
    private let viewModel: TabModel
    private weak var panelDelegate: SearchPanelDelegate?
    private var hosting: NSHostingView<SearchPanelView>?

    @objc public init(model: TabModelObjC, delegate: SearchPanelDelegate) {
        self.viewModel = model.model
        self.panelDelegate = delegate
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let view = SearchPanelView(
            model: viewModel,
            onPrev: { [weak self] in self?.panelDelegate?.searchPanelDidRequestPrevious() },
            onNext: { [weak self] in self?.panelDelegate?.searchPanelDidRequestNext() },
            onClose: { [weak self] in self?.requestClose() },
            onQueryChange: { [weak self] query, caseSensitive in
                self?.panelDelegate?.searchPanelDidUpdateQuery(query, caseSensitive: caseSensitive)
            }
        )
        let host = NSHostingView(rootView: view)
        host.translatesAutoresizingMaskIntoConstraints = false
        addSubview(host)
        NSLayoutConstraint.activate([
            host.leadingAnchor.constraint(equalTo: leadingAnchor),
            host.trailingAnchor.constraint(equalTo: trailingAnchor),
            host.topAnchor.constraint(equalTo: topAnchor),
            host.bottomAnchor.constraint(equalTo: bottomAnchor),
            heightAnchor.constraint(equalToConstant: 30),
        ])
        hosting = host
    }

    public required init?(coder: NSCoder) { nil }

    @objc public func showAndLoadFromPasteboard() {
        isHidden = false
        _ = loadFromPasteboard()
        viewModel.findInPage.focusToken &+= 1
    }

    @objc public func nextMatch() {
        if loadFromPasteboard() {
            return
        }
        panelDelegate?.searchPanelDidRequestNext()
    }

    @objc public func prevMatch() {
        if loadFromPasteboard() {
            return
        }
        panelDelegate?.searchPanelDidRequestPrevious()
    }

    @objc public func useSelection(_ text: String) {
        writeToPasteboard(text)
        if !isHidden {
            viewModel.findInPage.query = text
            panelDelegate?.searchPanelDidUpdateQuery(text, caseSensitive: viewModel.findInPage.caseSensitive)
            viewModel.findInPage.focusToken &+= 1
        }
    }

    private func requestClose() {
        isHidden = true
        panelDelegate?.searchPanelDidRequestClose()
    }

    private func loadFromPasteboard() -> Bool {
        let pasteboard = NSPasteboard(name: .find)
        guard let query = pasteboard.string(forType: .string) else {
            return false
        }
        if query == viewModel.findInPage.query {
            return false
        }
        viewModel.findInPage.query = query
        panelDelegate?.searchPanelDidUpdateQuery(query, caseSensitive: viewModel.findInPage.caseSensitive)
        return true
    }

    private func writeToPasteboard(_ text: String) {
        let pasteboard = NSPasteboard(name: .find)
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
