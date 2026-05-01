/*
 * Copyright (c) 2026, Filiph Sandström <filfat@hotmail.se>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

import AppKit
import SwiftUI

@objc(LBDialogs)
public final class Dialogs: NSObject {
    @MainActor
    @objc(presentAddBookmarkDialogForWindow:initialURL:initialTitle:promise:)
    public static func presentAddBookmark(
        window: NSWindow,
        initialURL: String?,
        initialTitle: String?,
        promise: LBBookmarkPromise
    ) {
        presentBookmark(
            window: window,
            title: "Add Bookmark",
            initialURL: initialURL ?? "",
            initialTitle: initialTitle ?? "",
            promise: promise
        )
    }

    @MainActor
    @objc(presentEditBookmarkDialogForWindow:bookmark:promise:)
    public static func presentEditBookmark(
        window: NSWindow,
        bookmark: LBBookmark,
        promise: LBBookmarkPromise
    ) {
        presentBookmark(
            window: window,
            title: "Edit Bookmark",
            initialURL: bookmark.urlString,
            initialTitle: bookmark.title ?? "",
            promise: promise
        )
    }

    @MainActor
    @objc(presentAddBookmarkFolderDialogForWindow:promise:)
    public static func presentAddBookmarkFolder(
        window: NSWindow,
        promise: LBBookmarkFolderPromise
    ) {
        presentFolder(
            window: window,
            title: "Add Folder",
            initialTitle: "",
            promise: promise
        )
    }

    @MainActor
    @objc(presentEditBookmarkFolderDialogForWindow:folder:promise:)
    public static func presentEditBookmarkFolder(
        window: NSWindow,
        folder: LBBookmarkFolder,
        promise: LBBookmarkFolderPromise
    ) {
        presentFolder(
            window: window,
            title: "Edit Folder",
            initialTitle: folder.title ?? "",
            promise: promise
        )
    }

    @MainActor
    private static func presentBookmark(
        window: NSWindow,
        title: String,
        initialURL: String,
        initialTitle: String,
        promise: LBBookmarkPromise
    ) {
        guard let contentView = window.contentView else {
            promise.reject()
            return
        }

        let presenter = DialogPresenter()
        let view = BookmarkSheetHost(
            title: title,
            initialURL: initialURL,
            initialTitle: initialTitle,
            onSubmit: { url, name in
                let bookmark = LBBookmark(
                    urlString: url,
                    title: name.isEmpty ? nil : name,
                    faviconPng: nil
                )
                promise.resolve(with: bookmark)
            },
            onCancel: {
                promise.reject()
            },
            onDismiss: { [weak presenter] in
                presenter?.dismiss()
            }
        )
        let host = NSHostingView(rootView: view)
        host.frame = .zero
        contentView.addSubview(host)
        presenter.host = host
    }

    @MainActor
    private static func presentFolder(
        window: NSWindow,
        title: String,
        initialTitle: String,
        promise: LBBookmarkFolderPromise
    ) {
        guard let contentView = window.contentView else {
            promise.reject()
            return
        }

        let presenter = DialogPresenter()
        let view = FolderSheetHost(
            title: title,
            initialTitle: initialTitle,
            onSubmit: { name in
                let folder = LBBookmarkFolder(title: name.isEmpty ? nil : name)
                promise.resolve(with: folder)
            },
            onCancel: {
                promise.reject()
            },
            onDismiss: { [weak presenter] in
                presenter?.dismiss()
            }
        )
        let host = NSHostingView(rootView: view)
        host.frame = .zero
        contentView.addSubview(host)
        presenter.host = host
    }
}

@MainActor
private final class DialogPresenter {
    var host: NSView?

    func dismiss() {
        host?.removeFromSuperview()
        host = nil
    }
}

private struct BookmarkSheetHost: View {
    let title: String
    @State private var isPresented = true
    @State private var url: String
    @State private var name: String
    let onSubmit: (String, String) -> Void
    let onCancel: () -> Void
    let onDismiss: () -> Void

    init(
        title: String,
        initialURL: String,
        initialTitle: String,
        onSubmit: @escaping (String, String) -> Void,
        onCancel: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.title = title
        self._url = State(initialValue: initialURL)
        self._name = State(initialValue: initialTitle)
        self.onSubmit = onSubmit
        self.onCancel = onCancel
        self.onDismiss = onDismiss
    }

    var body: some View {
        Color.clear
            .sheet(isPresented: $isPresented, onDismiss: onDismiss) {
                BookmarkSheetContent(
                    title: title,
                    url: $url,
                    name: $name,
                    onSubmit: {
                        onSubmit(url, name)
                        isPresented = false
                    },
                    onCancel: {
                        onCancel()
                        isPresented = false
                    }
                )
            }
    }
}

private struct BookmarkSheetContent: View {
    let title: String
    @Binding var url: String
    @Binding var name: String
    let onSubmit: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Form {
                TextField("URL", text: $url)
                TextField("Title", text: $name)
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button("OK", action: onSubmit)
                    .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .navigationTitle(title)
        .frame(minWidth: 400)
    }
}

private struct FolderSheetHost: View {
    let title: String
    @State private var isPresented = true
    @State private var name: String
    let onSubmit: (String) -> Void
    let onCancel: () -> Void
    let onDismiss: () -> Void

    init(
        title: String,
        initialTitle: String,
        onSubmit: @escaping (String) -> Void,
        onCancel: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.title = title
        self._name = State(initialValue: initialTitle)
        self.onSubmit = onSubmit
        self.onCancel = onCancel
        self.onDismiss = onDismiss
    }

    var body: some View {
        Color.clear
            .sheet(isPresented: $isPresented, onDismiss: onDismiss) {
                FolderSheetContent(
                    title: title,
                    name: $name,
                    onSubmit: {
                        onSubmit(name)
                        isPresented = false
                    },
                    onCancel: {
                        onCancel()
                        isPresented = false
                    }
                )
            }
    }
}

private struct FolderSheetContent: View {
    let title: String
    @Binding var name: String
    let onSubmit: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Form {
                TextField("Title", text: $name)
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button("OK", action: onSubmit)
                    .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .navigationTitle(title)
        .frame(minWidth: 400)
    }
}
