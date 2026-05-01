/*
 * Copyright (c) 2026, Filiph Sandström <filfat@hotmail.se>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#include <AK/Error.h>
#include <LibWebView/BookmarkStore.h>
#include <LibWebView/URL.h>
#include <Utilities/Conversions.h>

#import <Interface/Bridge/LBBookmarkPromise+Internal.h>

@implementation LBBookmarkPromise
{
    RefPtr<Core::Promise<WebView::BookmarkItem::Bookmark>> _promise;
    BOOL _settled;
}

- (instancetype)initWithPromise:(NonnullRefPtr<Core::Promise<WebView::BookmarkItem::Bookmark>>)promise
{
    if ((self = [super init])) {
        _promise = move(promise);
        _settled = NO;
    }
    return self;
}

- (void)resolveWithBookmark:(LBBookmark*)bookmark
{
    if (_settled)
        return;
    _settled = YES;

    auto url = WebView::sanitize_url(Ladybird::ns_string_to_string(bookmark.urlString));
    if (!url.has_value()) {
        _promise->reject(Error::from_errno(EINVAL));
        return;
    }

    Optional<String> title;
    if (bookmark.title && bookmark.title.length > 0)
        title = Ladybird::ns_string_to_string(bookmark.title);

    Optional<String> favicon_base64;
    if (bookmark.faviconPng) {
        auto* base64 = [bookmark.faviconPng base64EncodedStringWithOptions:0];
        favicon_base64 = Ladybird::ns_string_to_string(base64);
    }

    _promise->resolve(WebView::BookmarkItem::Bookmark {
        .url = url.release_value(),
        .title = move(title),
        .favicon_base64_png = move(favicon_base64),
    });
}

- (void)reject
{
    if (_settled)
        return;
    _settled = YES;
    _promise->reject(Error::from_errno(ECANCELED));
}

@end

@implementation LBBookmarkFolderPromise
{
    RefPtr<Core::Promise<WebView::BookmarkItem::Folder>> _promise;
    BOOL _settled;
}

- (instancetype)initWithPromise:(NonnullRefPtr<Core::Promise<WebView::BookmarkItem::Folder>>)promise
{
    if ((self = [super init])) {
        _promise = move(promise);
        _settled = NO;
    }
    return self;
}

- (void)resolveWithFolder:(LBBookmarkFolder*)folder
{
    if (_settled)
        return;
    _settled = YES;

    Optional<String> title;
    if (folder.title && folder.title.length > 0)
        title = Ladybird::ns_string_to_string(folder.title);

    _promise->resolve(WebView::BookmarkItem::Folder {
        .title = move(title),
        .children = {},
    });
}

- (void)reject
{
    if (_settled)
        return;
    _settled = YES;
    _promise->reject(Error::from_errno(ECANCELED));
}

@end
