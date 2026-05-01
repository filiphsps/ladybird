/*
 * Copyright (c) 2026, Filiph Sandström <filfat@hotmail.se>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#import <Interface/Bridge/LBBookmarkItem.h>

@implementation LBBookmark

- (instancetype)initWithURLString:(NSString*)urlString
                            title:(NSString*)title
                       faviconPng:(NSData*)faviconPng
{
    if ((self = [super init])) {
        _urlString = [urlString copy];
        _title = [title copy];
        _faviconPng = [faviconPng copy];
    }
    return self;
}

@end

@implementation LBBookmarkFolder

- (instancetype)initWithTitle:(NSString*)title
{
    if ((self = [super init])) {
        _title = [title copy];
    }
    return self;
}

@end
