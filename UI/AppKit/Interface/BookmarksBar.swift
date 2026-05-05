/*
 * Copyright (c) 2026, Filiph Sandström <filfat@hotmail.se>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

import AppKit
import SwiftUI

private let bookmarkItemSpacing: CGFloat = 2
private let bookmarkLeadingInset: CGFloat = 8
private let bookmarkButtonMaxWidth: CGFloat = 150
private let bookmarkButtonFontSize: CGFloat = 12
private let overflowTrailingInset: CGFloat = 4
private let hiddenPlacement = CGPoint(x: -10_000, y: -10_000)

@MainActor
private final class BookmarksBarModel: ObservableObject {
    @Published var items: [LBBookmarkMenuItem] = []
}

@MainActor
private protocol BookmarksBarCoordinator: AnyObject {
    func activate(_ item: LBBookmarkMenuItem)
    func openInNewTab(_ item: LBBookmarkMenuItem, activate: Bool)
    func openFolder(_ item: LBBookmarkMenuItem, anchor: NSView)
    func showContextMenu(for control: NSView, event: NSEvent)
    func openOverflow(anchor: NSView)
}

private final class BookmarkBarButton: NSButton, LBBookmarkItemView {
    let bookmarkMenuItem: LBBookmarkMenuItem?
    weak var coordinator: BookmarksBarCoordinator?

    init(menuItem: LBBookmarkMenuItem) {
        self.bookmarkMenuItem = menuItem
        super.init(frame: .zero)
        configure()
    }

    required init?(coder: NSCoder) {
        self.bookmarkMenuItem = nil
        super.init(coder: coder)
    }

    private func configure() {
        guard let item = bookmarkMenuItem else { return }
        title = item.title
        image = item.icon
        imagePosition = .imageLeading
        bezelStyle = .accessoryBarAction
        showsBorderOnlyWhileMouseInside = true
        font = NSFont.systemFont(ofSize: bookmarkButtonFontSize)
        controlSize = .regular
        cell?.lineBreakMode = .byTruncatingTail
        widthAnchor.constraint(lessThanOrEqualToConstant: bookmarkButtonMaxWidth).isActive = true
        toolTip = item.tooltip
        target = self
        action = #selector(handleClick)
    }

    @objc private func handleClick() {
        guard let item = bookmarkMenuItem else { return }
        let modifiers = NSEvent.modifierFlags

        if modifiers.contains(.command), item.kind == .bookmark {
            coordinator?.openInNewTab(item, activate: !modifiers.contains(.shift))
            return
        }

        if item.kind == .folder {
            coordinator?.openFolder(item, anchor: self)
            return
        }

        coordinator?.activate(item)
    }

    override func rightMouseDown(with event: NSEvent) {
        coordinator?.showContextMenu(for: self, event: event)
    }

    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.control) {
            coordinator?.showContextMenu(for: self, event: event)
            return
        }
        super.mouseDown(with: event)
    }
}

private struct BookmarkBarButtonView: NSViewRepresentable {
    let menuItem: LBBookmarkMenuItem
    weak var coordinator: BookmarksBarCoordinator?

    func makeNSView(context: Context) -> BookmarkBarButton {
        let button = BookmarkBarButton(menuItem: menuItem)
        button.coordinator = coordinator
        return button
    }

    func updateNSView(_ nsView: BookmarkBarButton, context: Context) {
        nsView.coordinator = coordinator
    }

    @MainActor
    func sizeThatFits(_ proposal: ProposedViewSize, nsView: BookmarkBarButton, context: Context) -> CGSize? {
        nsView.fittingSize
    }
}

private final class OverflowChevronButton: NSButton {
    weak var coordinator: BookmarksBarCoordinator?

    init() {
        super.init(frame: .zero)
        image = NSImage(systemSymbolName: "chevron.right", accessibilityDescription: "")
        bezelStyle = .accessoryBarAction
        showsBorderOnlyWhileMouseInside = true
        target = self
        action = #selector(handleClick)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    @objc private func handleClick() {
        coordinator?.openOverflow(anchor: self)
    }
}

private struct OverflowChevronView: NSViewRepresentable {
    weak var coordinator: BookmarksBarCoordinator?

    func makeNSView(context: Context) -> OverflowChevronButton {
        let button = OverflowChevronButton()
        button.coordinator = coordinator
        return button
    }

    func updateNSView(_ nsView: OverflowChevronButton, context: Context) {
        nsView.coordinator = coordinator
    }

    @MainActor
    func sizeThatFits(_ proposal: ProposedViewSize, nsView: OverflowChevronButton, context: Context) -> CGSize? {
        nsView.fittingSize
    }
}

private struct BookmarksBarLayout: Layout {
    let spacing: CGFloat
    let leadingInset: CGFloat
    let trailingInset: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let height = subviews.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty else { return }

        let bookmarkSubviews = subviews.dropLast()
        let chevron = subviews[subviews.count - 1]
        let chevronSize = chevron.sizeThatFits(.unspecified)

        var totalNeeded = leadingInset
        for sub in bookmarkSubviews {
            totalNeeded += sub.sizeThatFits(.unspecified).width + spacing
        }

        let needsOverflow = totalNeeded > bounds.width
        let usableWidth = needsOverflow
            ? bounds.width - chevronSize.width - trailingInset - spacing
            : bounds.width

        var x = bounds.minX + leadingInset
        for sub in bookmarkSubviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width <= usableWidth {
                sub.place(
                    at: CGPoint(x: x, y: bounds.midY - size.height / 2),
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            } else {
                sub.place(at: hiddenPlacement, proposal: .zero)
            }
        }

        if needsOverflow {
            chevron.place(
                at: CGPoint(
                    x: bounds.maxX - chevronSize.width - trailingInset,
                    y: bounds.midY - chevronSize.height / 2
                ),
                proposal: ProposedViewSize(chevronSize)
            )
        } else {
            chevron.place(at: hiddenPlacement, proposal: .zero)
        }
    }
}

private struct BookmarksBarContentView: View {
    @ObservedObject var model: BookmarksBarModel
    weak var coordinator: BookmarksBarCoordinator?

    var body: some View {
        BookmarksBarLayout(
            spacing: bookmarkItemSpacing,
            leadingInset: bookmarkLeadingInset,
            trailingInset: overflowTrailingInset
        ) {
            ForEach(model.items, id: \.identifier) { item in
                BookmarkBarButtonView(menuItem: item, coordinator: coordinator)
            }
            OverflowChevronView(coordinator: coordinator)
        }
    }
}

@objc(BookmarksBar)
class BookmarksBar: NSView, BookmarksBarCoordinator {
    private let model = BookmarksBarModel()
    private var hosting: NSHostingView<BookmarksBarContentView>?
    private var folderPopover: NSPopover?

    @objc var selected_bookmark_menu_item_id: String?
    @objc var selected_bookmark_menu_target_folder_id: String?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    @objc convenience init() {
        self.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        let view = BookmarksBarContentView(model: model, coordinator: self)
        let host = NSHostingView(rootView: view)
        host.translatesAutoresizingMaskIntoConstraints = false
        addSubview(host)
        NSLayoutConstraint.activate([
            host.leadingAnchor.constraint(equalTo: leadingAnchor),
            host.trailingAnchor.constraint(equalTo: trailingAnchor),
            host.topAnchor.constraint(equalTo: topAnchor),
            host.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        hosting = host

        clipsToBounds = true
        rebuild()
    }

    // MARK: - Public API

    @objc func rebuild() {
        closeBookmarkFolders()
        model.items = LBBookmarkActions.menuItems()
    }

    @objc func closeBookmarkFolders() {
        folderPopover?.close()
        folderPopover = nil
    }

    @objc(bookmarkFolderDidClose:)
    func bookmarkFolderDidClose(_ folder: NSPopover) {
        if folderPopover === folder {
            folderPopover = nil
        }
    }

    @objc(showContextMenu:event:)
    func showContextMenu(_ control: AnyObject, event: NSEvent) {
        guard let provider = control as? LBBookmarkItemView,
              let item = provider.bookmarkMenuItem,
              let view = control as? NSView
        else { return }

        selected_bookmark_menu_item_id = item.identifier
        selected_bookmark_menu_target_folder_id = item.targetFolderIdentifier

        switch item.kind {
        case .bookmark:
            NSMenu.popUpContextMenu(LBBookmarkActions.bookmarkContextMenu(), with: event, for: view)
        case .folder:
            NSMenu.popUpContextMenu(LBBookmarkActions.bookmarkFolderContextMenu(), with: event, for: view)
        @unknown default:
            break
        }
    }

    // MARK: - BookmarksBarCoordinator

    fileprivate func activate(_ item: LBBookmarkMenuItem) {
        LBBookmarkActions.activateBookmark(item.identifier)
    }

    fileprivate func openInNewTab(_ item: LBBookmarkMenuItem, activate: Bool) {
        LBBookmarkActions.openBookmark(inNewTab: item.identifier, activateTab: activate)
    }

    fileprivate func openFolder(_ item: LBBookmarkMenuItem, anchor: NSView) {
        closeBookmarkFolders()

        folderPopover = LBBookmarkActions.openFolderPopover(
            item.identifier,
            bookmarksBar: self,
            anchoredTo: anchor,
            preferredEdge: .maxY
        )
    }

    fileprivate func showContextMenu(for control: NSView, event: NSEvent) {
        showContextMenu(control as AnyObject, event: event)
    }

    fileprivate func openOverflow(anchor: NSView) {
        let hiddenIds = collectHiddenBookmarkIds()
        let menu = LBBookmarkActions.overflowMenu(forItemIds: hiddenIds)
        guard menu.numberOfItems > 0 else { return }
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: anchor.bounds.height), in: anchor)
    }

    private func collectHiddenBookmarkIds() -> [String] {
        var ids: [String] = []
        var stack: [NSView] = subviews
        while let view = stack.popLast() {
            if let button = view as? BookmarkBarButton, let item = button.bookmarkMenuItem {
                let buttonFrame = button.convert(button.bounds, to: self)
                if buttonFrame.maxX < 0 || buttonFrame.minX > bounds.width {
                    ids.append(item.identifier)
                }
            }
            stack.append(contentsOf: view.subviews)
        }
        return ids
    }

    // MARK: - Bar background interaction

    override func rightMouseDown(with event: NSEvent) {
        showBarBackgroundContextMenu(event: event)
    }

    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.control) {
            showBarBackgroundContextMenu(event: event)
            return
        }
        super.mouseDown(with: event)
    }

    private func showBarBackgroundContextMenu(event: NSEvent) {
        selected_bookmark_menu_item_id = ""
        selected_bookmark_menu_target_folder_id = nil
        NSMenu.popUpContextMenu(LBBookmarkActions.bookmarksBarContextMenu(), with: event, for: self)
    }
}
