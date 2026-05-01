/*
 * Copyright (c) 2026, Filiph Sandström <filfat@hotmail.se>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#pragma once

#include <AK/NonnullRefPtr.h>
#include <LibCore/Promise.h>
#include <LibWebView/BookmarkStore.h>

#import <Interface/Bridge/LBBookmarkPromise.h>

@interface LBBookmarkPromise ()
- (instancetype)initWithPromise:(NonnullRefPtr<Core::Promise<WebView::BookmarkItem::Bookmark>>)promise;
@end

@interface LBBookmarkFolderPromise ()
- (instancetype)initWithPromise:(NonnullRefPtr<Core::Promise<WebView::BookmarkItem::Folder>>)promise;
@end
