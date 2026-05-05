/*
 * Copyright (c) 2026, Filiph Sandström <filfat@hotmail.se>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#pragma once

#include <AK/Optional.h>
#include <AK/String.h>
#include <LibGfx/Point.h>
#include <LibWebView/BookmarkStore.h>

#import <Interface/Bridge/LBBookmarkActions.h>

@interface LBBookmarkActions (Internal)

+ (void)showContextMenuForBookmarksBar:(id)bookmarksBar
                       contentPosition:(Gfx::IntPoint)position
                                  view:(NSView*)view
                          bookmarkItem:(Optional<WebView::BookmarkItem const&>)item
                        targetFolderID:(Optional<String const&>)targetFolderId;

@end
