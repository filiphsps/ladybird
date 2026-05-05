/*
 * Copyright (c) 2026, Filiph Sandström <filfat@hotmail.se>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#include <LibWebView/Menu.h>

#import <Interface/Bridge/LBBookmarkMenuItem+Internal.h>
#import <Utilities/Conversions.h>

#if !__has_feature(objc_arc)
#    error "This project requires ARC"
#endif

static constexpr CGFloat const BOOKMARK_ICON_SIZE = 16;

static NSImage* image_for_bookmark_action(WebView::Action const& action)
{
    if (auto icon = action.base64_png_icon(); icon.has_value())
        return Ladybird::image_from_base64_png(*icon, NSMakeSize(BOOKMARK_ICON_SIZE, BOOKMARK_ICON_SIZE));
    return [NSImage imageWithSystemSymbolName:@"globe" accessibilityDescription:@""];
}

@implementation LBBookmarkMenuItem

- (instancetype)initWithKind:(LBBookmarkMenuItemKind)kind
                  identifier:(NSString*)identifier
                       title:(NSString*)title
                     tooltip:(NSString*)tooltip
      targetFolderIdentifier:(NSString*)targetFolderIdentifier
                        icon:(NSImage*)icon
{
    if (self = [super init]) {
        _kind = kind;
        _identifier = [identifier copy];
        _title = [title copy];
        _tooltip = [tooltip copy];
        _targetFolderIdentifier = [targetFolderIdentifier copy];
        _icon = icon;
    }
    return self;
}

+ (instancetype)itemFromBookmarkAction:(WebView::Action const&)action
{
    auto identifier = action.properties().get("id"sv).value_or({});
    auto target_folder = action.properties().get("target_folder_id"sv);

    return [[LBBookmarkMenuItem alloc] initWithKind:LBBookmarkMenuItemKindBookmark
                                         identifier:Ladybird::string_to_ns_string(identifier)
                                              title:Ladybird::string_to_ns_string(action.text())
                                            tooltip:Ladybird::string_to_ns_string(action.tooltip())
                             targetFolderIdentifier:target_folder.has_value() ? Ladybird::string_to_ns_string(*target_folder) : nil
                                               icon:image_for_bookmark_action(action)];
}

+ (instancetype)itemFromFolderMenu:(WebView::Menu const&)folder
{
    auto identifier = folder.properties().get("id"sv).value_or({});
    auto target_folder = folder.properties().get("target_folder_id"sv);

    return [[LBBookmarkMenuItem alloc] initWithKind:LBBookmarkMenuItemKindFolder
                                         identifier:Ladybird::string_to_ns_string(identifier)
                                              title:Ladybird::string_to_ns_string(folder.title())
                                            tooltip:nil
                             targetFolderIdentifier:target_folder.has_value() ? Ladybird::string_to_ns_string(*target_folder) : nil
                                               icon:[NSImage imageWithSystemSymbolName:@"folder" accessibilityDescription:@""]];
}

@end
