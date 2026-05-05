/*
 * Copyright (c) 2023-2026, Tim Flynn <trflynn89@ladybird.org>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#include <Application/EventLoopImplementationMacOS.h>
#include <LibCore/ArgsParser.h>
#include <LibCore/EventLoop.h>
#include <LibCore/ThreadEventQueue.h>
#include <LibWebView/URL.h>
#include <LibWebView/ViewImplementation.h>
#include <Utilities/Conversions.h>

#import <Application/Application.h>
#import <Application/ApplicationDelegate.h>
#import <Interface/Bridge/LBBookmarkActions+Internal.h>
#import <Interface/Bridge/LBBookmarkItem.h>
#import <Interface/Bridge/LBBookmarkPromise+Internal.h>
#import <Interface/LadybirdWebView.h>
#import <Interface/Tab.h>
#import <Interface/TabController.h>

#import "LadybirdSwift.h"

#if !__has_feature(objc_arc)
#    error "This project requires ARC"
#endif

namespace Ladybird {

Application::Application() = default;

NonnullOwnPtr<Core::EventLoop> Application::create_platform_event_loop()
{
    if (!browser_options().headless_mode.has_value()) {
        Core::EventLoopManager::install(*new EventLoopManagerMacOS);
        [::Application sharedApplication];
    }

    return WebView::Application::create_platform_event_loop();
}

Optional<WebView::ViewImplementation&> Application::active_web_view() const
{
    ApplicationDelegate* delegate = [NSApp delegate];

    if (auto* tab = [delegate activeTab])
        return [[tab web_view] view];
    return {};
}

Optional<WebView::ViewImplementation&> Application::open_blank_new_tab(Web::HTML::ActivateTab activate_tab) const
{
    ApplicationDelegate* delegate = [NSApp delegate];

    auto* controller = [delegate createNewTab:activate_tab fromTab:[delegate activeTab]];
    if (activate_tab == Web::HTML::ActivateTab::Yes)
        [controller focusWebView];
    else
        [controller focusWebViewWhenActivated];
    auto* tab = (Tab*)[controller window];

    return [[tab web_view] view];
}

Optional<ByteString> Application::ask_user_for_download_path(StringView file) const
{
    auto* panel = [NSSavePanel savePanel];
    [panel setNameFieldStringValue:Ladybird::string_to_ns_string(file)];
    [panel setTitle:@"Select save location"];

    if ([panel runModal] != NSModalResponseOK)
        return {};

    return Ladybird::ns_string_to_byte_string([[panel URL] path]);
}

void Application::display_download_confirmation_dialog(StringView download_name, LexicalPath const& path) const
{
    ApplicationDelegate* delegate = [NSApp delegate];

    auto message = MUST(String::formatted("{} saved to: {}", download_name, path));

    auto* dialog = [[NSAlert alloc] init];
    [dialog setMessageText:Ladybird::string_to_ns_string(message)];
    [[dialog addButtonWithTitle:@"OK"] setTag:NSModalResponseOK];
    [[dialog addButtonWithTitle:@"Open folder"] setTag:NSModalResponseContinue];

    __block auto* ns_path = Ladybird::string_to_ns_string(path.string());

    [dialog beginSheetModalForWindow:[delegate activeTab]
                   completionHandler:^(NSModalResponse response) {
                       if (response == NSModalResponseContinue) {
                           [[NSWorkspace sharedWorkspace] selectFile:ns_path inFileViewerRootedAtPath:@""];
                       }
                   }];
}

void Application::display_error_dialog(StringView error_message) const
{
    ApplicationDelegate* delegate = [NSApp delegate];

    auto* dialog = [[NSAlert alloc] init];
    [dialog setMessageText:Ladybird::string_to_ns_string(error_message)];

    [dialog beginSheetModalForWindow:[delegate activeTab]
                   completionHandler:nil];
}

Utf16String Application::clipboard_text() const
{
    auto* paste_board = [NSPasteboard generalPasteboard];

    if (auto* contents = [paste_board stringForType:NSPasteboardTypeString])
        return Ladybird::ns_string_to_utf16_string(contents);
    return {};
}

Vector<Web::Clipboard::SystemClipboardRepresentation> Application::clipboard_entries() const
{
    Vector<Web::Clipboard::SystemClipboardRepresentation> representations;
    auto* paste_board = [NSPasteboard generalPasteboard];

    for (NSPasteboardType type : [paste_board types]) {
        String mime_type;

        if (type == NSPasteboardTypeString)
            mime_type = "text/plain"_string;
        else if (type == NSPasteboardTypeHTML)
            mime_type = "text/html"_string;
        else if (type == NSPasteboardTypePNG)
            mime_type = "image/png"_string;
        else
            continue;

        auto data = Ladybird::ns_data_to_string([paste_board dataForType:type]);
        representations.empend(move(data), move(mime_type));
    }

    return representations;
}

void Application::insert_clipboard_entry(Web::Clipboard::SystemClipboardRepresentation entry)
{
    NSPasteboardType pasteboard_type = nil;

    // https://w3c.github.io/clipboard-apis/#os-specific-well-known-format
    if (entry.mime_type == "text/plain"sv)
        pasteboard_type = NSPasteboardTypeString;
    else if (entry.mime_type == "text/html"sv)
        pasteboard_type = NSPasteboardTypeHTML;
    else if (entry.mime_type == "image/png"sv)
        pasteboard_type = NSPasteboardTypePNG;
    else
        return;

    auto* paste_board = [NSPasteboard generalPasteboard];
    [paste_board clearContents];

    [paste_board setData:Ladybird::string_to_ns_data(entry.data)
                 forType:pasteboard_type];
}

void Application::rebuild_bookmarks_menu() const
{
    ApplicationDelegate* delegate = [NSApp delegate];
    [delegate rebuildBookmarksMenu];
}

void Application::update_bookmarks_bar_display(bool show_bookmarks_bar) const
{
    ApplicationDelegate* delegate = [NSApp delegate];
    [delegate updateBookmarksBarDisplay:show_bookmarks_bar];
}

void Application::show_bookmark_context_menu(Gfx::IntPoint content_position, Optional<WebView::BookmarkItem const&> item, Optional<String const&> target_folder_id)
{
    ApplicationDelegate* delegate = [NSApp delegate];

    if (auto* tab = [delegate activeTab]) {
        [LBBookmarkActions showContextMenuForBookmarksBar:[tab bookmarksBar]
                                          contentPosition:content_position
                                                     view:[tab web_view]
                                             bookmarkItem:item
                                           targetFolderID:target_folder_id];
    }
}

Optional<Application::BookmarkID> Application::bookmark_item_id_for_context_menu() const
{
    ApplicationDelegate* delegate = [NSApp delegate];

    if (auto* tab = [delegate activeTab]) {
        auto* bookmarks_bar = [tab bookmarksBar];

        return Application::BookmarkID {
            .id = Ladybird::ns_string_to_string([bookmarks_bar selected_bookmark_menu_item_id]),
            .target_folder_id = [bookmarks_bar selected_bookmark_menu_target_folder_id]
                ? Optional<String> { Ladybird::ns_string_to_string([bookmarks_bar selected_bookmark_menu_target_folder_id]) }
                : Optional<String> {},
        };
    }

    return {};
}

NonnullRefPtr<Application::BookmarkPromise> Application::display_add_bookmark_dialog() const
{
    ApplicationDelegate* delegate = [NSApp delegate];

    NSString* url_string = nil;
    NSString* title_string = nil;

    if (auto view = active_web_view(); view.has_value()) {
        url_string = Ladybird::string_to_ns_string(view->url().serialize());
        title_string = Ladybird::utf16_string_to_ns_string(view->title());
    }

    auto promise = BookmarkPromise::construct();
    auto* objc_promise = [[LBBookmarkPromise alloc] initWithPromise:promise];

    [LBDialogs presentAddBookmarkDialogForWindow:[delegate activeTab]
                                      initialURL:url_string
                                    initialTitle:title_string
                                         promise:objc_promise];
    return promise;
}

NonnullRefPtr<Application::BookmarkPromise> Application::display_edit_bookmark_dialog(WebView::BookmarkItem::Bookmark const& current_bookmark) const
{
    ApplicationDelegate* delegate = [NSApp delegate];

    NSString* title_string = current_bookmark.title.has_value()
        ? Ladybird::string_to_ns_string(*current_bookmark.title)
        : nil;
    NSData* favicon_data = nil;
    if (current_bookmark.favicon_base64_png.has_value()) {
        auto* base64 = Ladybird::string_to_ns_string(*current_bookmark.favicon_base64_png);
        favicon_data = [[NSData alloc] initWithBase64EncodedString:base64 options:0];
    }

    auto* lb_bookmark = [[LBBookmark alloc] initWithURLString:Ladybird::string_to_ns_string(current_bookmark.url.serialize())
                                                        title:title_string
                                                   faviconPng:favicon_data];

    auto promise = BookmarkPromise::construct();
    auto* objc_promise = [[LBBookmarkPromise alloc] initWithPromise:promise];

    [LBDialogs presentEditBookmarkDialogForWindow:[delegate activeTab]
                                         bookmark:lb_bookmark
                                          promise:objc_promise];
    return promise;
}

NonnullRefPtr<Application::BookmarkFolderPromise> Application::display_add_bookmark_folder_dialog() const
{
    ApplicationDelegate* delegate = [NSApp delegate];

    auto promise = BookmarkFolderPromise::construct();
    auto* objc_promise = [[LBBookmarkFolderPromise alloc] initWithPromise:promise];

    [LBDialogs presentAddBookmarkFolderDialogForWindow:[delegate activeTab]
                                               promise:objc_promise];
    return promise;
}

NonnullRefPtr<Application::BookmarkFolderPromise> Application::display_edit_bookmark_folder_dialog(WebView::BookmarkItem::Folder const& current_folder) const
{
    ApplicationDelegate* delegate = [NSApp delegate];

    NSString* title_string = current_folder.title.has_value()
        ? Ladybird::string_to_ns_string(*current_folder.title)
        : nil;
    auto* lb_folder = [[LBBookmarkFolder alloc] initWithTitle:title_string];

    auto promise = BookmarkFolderPromise::construct();
    auto* objc_promise = [[LBBookmarkFolderPromise alloc] initWithPromise:promise];

    [LBDialogs presentEditBookmarkFolderDialogForWindow:[delegate activeTab]
                                                 folder:lb_folder
                                                promise:objc_promise];
    return promise;
}

void Application::on_devtools_enabled() const
{
    WebView::Application::on_devtools_enabled();

    ApplicationDelegate* delegate = [NSApp delegate];
    [delegate onDevtoolsEnabled];
}

void Application::on_devtools_disabled() const
{
    WebView::Application::on_devtools_disabled();

    ApplicationDelegate* delegate = [NSApp delegate];
    [delegate onDevtoolsDisabled];
}

}

@interface Application ()
@end

@implementation Application

#pragma mark - NSApplication

- (void)terminate:(id)sender
{
    Core::EventLoop::current().quit(0);
}

- (void)sendEvent:(NSEvent*)event
{
    if ([event type] == NSEventTypeApplicationDefined) {
        Core::ThreadEventQueue::current().process();
    } else {
        [super sendEvent:event];
    }
}

@end
