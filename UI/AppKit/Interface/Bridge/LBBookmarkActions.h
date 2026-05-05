/*
 * Copyright (c) 2026, Filiph Sandström <filfat@hotmail.se>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#pragma once

#import <Cocoa/Cocoa.h>

@class LBBookmarkMenuItem;

NS_ASSUME_NONNULL_BEGIN

@interface LBBookmarkActions : NSObject

+ (NSArray<LBBookmarkMenuItem*>*)menuItems;

+ (void)activateBookmark:(NSString*)bookmarkId;
+ (void)openBookmarkInNewTab:(NSString*)bookmarkId activateTab:(BOOL)activateTab;

+ (NSPopover* _Nullable)openFolderPopover:(NSString*)folderId
                             bookmarksBar:(id)bookmarksBar
                               anchoredTo:(NSView*)view
                            preferredEdge:(NSRectEdge)edge;

+ (NSMenu*)overflowMenuForItemIds:(NSArray<NSString*>*)itemIds;

+ (NSMenu*)bookmarksBarContextMenu;
+ (NSMenu*)bookmarkContextMenu;
+ (NSMenu*)bookmarkFolderContextMenu;

@end

NS_ASSUME_NONNULL_END
