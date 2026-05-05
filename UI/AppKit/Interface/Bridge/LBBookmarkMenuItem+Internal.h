/*
 * Copyright (c) 2026, Filiph Sandström <filfat@hotmail.se>
 *
 * SPDX-License-Identifier: BSD-2-Clause
 */

#pragma once

#include <LibWebView/Forward.h>

#import <Interface/Bridge/LBBookmarkMenuItem.h>

@interface LBBookmarkMenuItem (Internal)

+ (instancetype)itemFromBookmarkAction:(WebView::Action const&)action;
+ (instancetype)itemFromFolderMenu:(WebView::Menu const&)folder;

@end
