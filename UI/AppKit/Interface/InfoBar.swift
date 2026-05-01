/*
 * Copyright (c) 2025, Tim Flynn <trflynn89@ladybird.org>
 * Copyright (c) 2026, Filiph Sandström <filfat@hotmail.se>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

import AppKit
import SwiftUI

private struct InfoBarView: View {
    let message: String
    let dismissTitle: String
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Text(message)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer()
            Button(dismissTitle, action: onDismiss)
                .buttonStyle(.bordered)
        }
        .safeAreaPadding(.horizontal, 16)
    }
}

@objc(InfoBar)
public final class InfoBar: NSStackView {
    private var hosting: NSHostingView<InfoBarView>?
    private var onDismissed: (() -> Void)?

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    @objc public convenience init() {
        self.init(frame: .zero)
    }

    private func commonInit() {
        orientation = .horizontal
        edgeInsets = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        heightAnchor.constraint(equalToConstant: 40).isActive = true
        isHidden = true
    }

    @objc(showWithMessage:dismissButtonTitle:dismissButtonClicked:activeTab:)
    public func show(message: String,
                     dismissButtonTitle: String,
                     dismissButtonClicked: @escaping () -> Void,
                     activeTab: NSWindow?) {
        onDismissed = dismissButtonClicked
        let view = InfoBarView(
            message: message,
            dismissTitle: dismissButtonTitle,
            onDismiss: { [weak self] in self?.dismissTapped() }
        )
        if let hosting {
            hosting.rootView = view
        } else {
            let host = NSHostingView(rootView: view)
            host.translatesAutoresizingMaskIntoConstraints = false
            addView(host, in: .leading)
            host.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            host.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            hosting = host
        }
        if let tab = activeTab {
            attach(to: tab)
        }
        isHidden = false
    }

    @objc public func hide() {
        removeFromSuperview()
        isHidden = true
    }

    @objc(tabBecameActive:)
    public func tabBecameActive(_ tab: NSWindow) {
        if !isHidden {
            attach(to: tab)
        }
    }

    private func attach(to tab: NSWindow) {
        removeFromSuperview()
        guard let content = tab.contentView as? NSStackView else { return }
        content.addView(self, in: .trailing)
        leadingAnchor.constraint(equalTo: content.leadingAnchor).isActive = true
    }

    private func dismissTapped() {
        onDismissed?()
        hide()
    }
}
