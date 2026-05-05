/*
 * Copyright (c) 2026, Filiph Sandström <filfat@hotmail.se>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#include <LibWebView/Application.h>
#include <LibWebView/BookmarkStore.h>
#include <LibWebView/Menu.h>

#import <Interface/BookmarkFolder.h>
#import <Interface/Bridge/LBBookmarkActions+Internal.h>
#import <Interface/Bridge/LBBookmarkMenuItem+Internal.h>
#import <Interface/Event.h>
#import <Interface/Menu.h>
#import <Utilities/Conversions.h>

#import "LadybirdSwift.h"

#if !__has_feature(objc_arc)
#    error "This project requires ARC"
#endif

static Optional<WebView::Menu&> find_folder_by_id(WebView::Menu& menu, StringView id)
{
    for (auto& item : menu.items()) {
        auto* submenu_ptr = item.get_pointer<NonnullRefPtr<WebView::Menu>>();
        if (!submenu_ptr)
            continue;

        auto& submenu = **submenu_ptr;

        if (auto submenu_id = submenu.properties().get("id"sv); submenu_id.has_value() && *submenu_id == id)
            return submenu;

        if (auto descendant = find_folder_by_id(submenu, id); descendant.has_value())
            return descendant;
    }

    return {};
}

static Optional<WebView::Action&> find_bookmark_action_by_id(WebView::Menu& menu, StringView id)
{
    for (auto& item : menu.items()) {
        auto found = item.visit(
            [&](NonnullRefPtr<WebView::Action> const& action) -> Optional<WebView::Action&> {
                if (action->id() != WebView::ActionID::BookmarkItem)
                    return {};
                if (auto action_id = action->properties().get("id"sv); action_id.has_value() && *action_id == id)
                    return *action;
                return {};
            },
            [&](NonnullRefPtr<WebView::Menu> const& submenu) -> Optional<WebView::Action&> {
                return find_bookmark_action_by_id(*submenu, id);
            },
            [](WebView::Separator) -> Optional<WebView::Action&> {
                return {};
            });

        if (found.has_value())
            return found;
    }

    return {};
}

@implementation LBBookmarkActions

+ (NSArray<LBBookmarkMenuItem*>*)menuItems
{
    auto* items = [[NSMutableArray alloc] init];

    for (auto const& item : WebView::Application::the().bookmarks_menu().items()) {
        auto* menu_item = item.visit(
            [](NonnullRefPtr<WebView::Action> const& action) -> LBBookmarkMenuItem* {
                if (action->id() != WebView::ActionID::BookmarkItem)
                    return nil;
                return [LBBookmarkMenuItem itemFromBookmarkAction:*action];
            },
            [](NonnullRefPtr<WebView::Menu> const& folder) -> LBBookmarkMenuItem* {
                return [LBBookmarkMenuItem itemFromFolderMenu:*folder];
            },
            [](WebView::Separator) -> LBBookmarkMenuItem* {
                return nil;
            });

        if (menu_item)
            [items addObject:menu_item];
    }

    return items;
}

+ (void)activateBookmark:(NSString*)bookmarkId
{
    auto id = Ladybird::ns_string_to_string(bookmarkId);
    if (auto action = find_bookmark_action_by_id(WebView::Application::the().bookmarks_menu(), id); action.has_value())
        action->activate();
}

+ (void)openBookmarkInNewTab:(NSString*)bookmarkId activateTab:(BOOL)activateTab
{
    auto bookmark_id = Ladybird::ns_string_to_string(bookmarkId);
    auto activate_tab = activateTab ? Web::HTML::ActivateTab::Yes : Web::HTML::ActivateTab::No;
    WebView::Application::the().open_bookmark_in_new_tab(bookmark_id, activate_tab);
}

+ (NSPopover*)openFolderPopover:(NSString*)folderId
                   bookmarksBar:(id)bookmarksBar
                     anchoredTo:(NSView*)view
                  preferredEdge:(NSRectEdge)edge
{
    auto id = Ladybird::ns_string_to_string(folderId);
    auto folder = find_folder_by_id(WebView::Application::the().bookmarks_menu(), id);
    if (!folder.has_value())
        return nil;

    if (folder->size() == 0)
        return nil;

    auto* popover = [[BookmarkFolderPopover alloc] init:*folder bookmarksBar:bookmarksBar parentFolder:nil];
    [popover showRelativeToView:view preferredEdge:edge];
    return popover;
}

+ (NSMenu*)overflowMenuForItemIds:(NSArray<NSString*>*)itemIds
{
    auto* menu = [[NSMenu alloc] init];
    auto* hidden = [NSSet setWithArray:itemIds];

    for (auto const& item : WebView::Application::the().bookmarks_menu().items()) {
        item.visit(
            [&](NonnullRefPtr<WebView::Action> const& action) {
                if (action->id() != WebView::ActionID::BookmarkItem)
                    return;
                auto identifier = action->properties().get("id"sv).value_or({});
                if (![hidden containsObject:Ladybird::string_to_ns_string(identifier)])
                    return;
                [menu addItem:Ladybird::create_application_menu_item(action)];
            },
            [&](NonnullRefPtr<WebView::Menu> const& folder) {
                auto identifier = folder->properties().get("id"sv).value_or({});
                if (![hidden containsObject:Ladybird::string_to_ns_string(identifier)])
                    return;

                auto* folder_item = [[NSMenuItem alloc] initWithTitle:Ladybird::string_to_ns_string(folder->title())
                                                               action:nil
                                                        keyEquivalent:@""];
                [folder_item setSubmenu:Ladybird::create_application_menu(folder)];
                [menu addItem:folder_item];
            },
            [](WebView::Separator) {});
    }

    return menu;
}

+ (NSMenu*)bookmarksBarContextMenu
{
    static NSMenu* menu = nil;
    if (!menu)
        menu = Ladybird::create_application_menu(WebView::Application::the().bookmarks_bar_context_menu());
    return menu;
}

+ (NSMenu*)bookmarkContextMenu
{
    static NSMenu* menu = nil;
    if (!menu)
        menu = Ladybird::create_application_menu(WebView::Application::the().bookmark_context_menu());
    return menu;
}

+ (NSMenu*)bookmarkFolderContextMenu
{
    static NSMenu* menu = nil;
    if (!menu)
        menu = Ladybird::create_application_menu(WebView::Application::the().bookmark_folder_context_menu());
    return menu;
}

+ (void)showContextMenuForBookmarksBar:(id)bookmarksBar
                       contentPosition:(Gfx::IntPoint)position
                                  view:(NSView*)view
                          bookmarkItem:(Optional<WebView::BookmarkItem const&>)item
                        targetFolderID:(Optional<String const&>)targetFolderId
{
    auto* event = Ladybird::create_context_menu_mouse_event(view, position);

    if (item.has_value()) {
        [bookmarksBar setSelected_bookmark_menu_item_id:Ladybird::string_to_ns_string(item->id)];
        [bookmarksBar setSelected_bookmark_menu_target_folder_id:targetFolderId.has_value()
                ? Ladybird::string_to_ns_string(*targetFolderId)
                : nil];

        if (item->is_bookmark())
            [NSMenu popUpContextMenu:[self bookmarkContextMenu] withEvent:event forView:view];
        else if (item->is_folder())
            [NSMenu popUpContextMenu:[self bookmarkFolderContextMenu] withEvent:event forView:view];
    } else {
        [bookmarksBar setSelected_bookmark_menu_item_id:@""];
        [bookmarksBar setSelected_bookmark_menu_target_folder_id:nil];

        [NSMenu popUpContextMenu:[self bookmarksBarContextMenu] withEvent:event forView:view];
    }
}

@end
